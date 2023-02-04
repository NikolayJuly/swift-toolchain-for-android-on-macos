import ConsoleKit
import Foundation
import Logging
import Shell

protocol BuildableItemDependency {
    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String]
}

extension BuildableItemDependency where Self: BuildableItem {
    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String] {
        let depBuildUrl = config.buildLocation(for: self)
        let res = depName + "_DIR=\"\(depBuildUrl.path)/cmake/modules\""
        return [res]
    }
}

protocol BuildableItem {
    // Will be used as folder or file name part, where needed
    var name: String { get }

    var buildSubfolder: String? { get }

    var dependencies: [String: BuildableItemDependency] { get }

    var targets: [String] { get }

    var underlyingRepo: Checkoutable? { get }

    func sourceLocation(using buildConfig: BuildConfig) -> URL

    func cmakeCacheEntries(config: BuildConfig) -> [String]
}

extension BuildableItem {
    var buildSubfolder: String? { nil }

    var dependencies: [String: BuildableItemDependency] { [:] }

    // Most of repos has 1 default target
    var targets: [String] { [] }

    func cmakeCacheEntries(config: BuildConfig) -> [String] { [] }
}

extension BuildableItem where Self: Checkoutable {
    var name: String { repoName }

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        var resUrl = buildConfig.location(for: self)
        if let buildSubfolder {
            resUrl = resUrl.appendingPathComponent(buildSubfolder, isDirectory: true)
        }
        return resUrl
    }

    var underlyingRepo: Checkoutable? {
        return self
    }
}

extension BuildConfig {
    func buildLocation(for repo: BuildableItem) -> URL {
        return buildsRootFolder.appendingPathComponent(repo.name, isDirectory: true)
    }
}

final class ConfigureRepoStep: BuildStep {
    var stepName: String {
        "configure-" + buildableItem.name
    }

    init(buildableItem: BuildableItem) {
        self.buildableItem = buildableItem
    }

    func shouldBeExecuted(_ completedSteps: [String]) -> Bool {
        // if build failed, we might want ro re-run configure, because we might change smake cache to fix it
        let buildStepName = NinjaBuildStep.buildStepName(for: buildableItem)
        let buildAlreadyCompleted = completedSteps.contains(buildStepName)
        return !buildAlreadyCompleted
    }

    func prepare(_ config: BuildConfig, logger: Logging.Logger) async throws {
        // I would prefer don't have secret check for other protocol, but looks like simplest solution for now
        if let checkoutable = buildableItem.underlyingRepo {
            logger.info("Step is `Checkoutable`, so executing git reset to needed revision")
            let object: String = try checkoutable.checkoutObject(using: self.defaultRevisionsMap)
            let repoFolder = config.location(for: checkoutable)
            let gitReset = GitReset(repoUrl: repoFolder, object: object, logger: logger)
            try await gitReset.execute()

            logger.info("Checking for a ptach for \(checkoutable.repoName)")
            try await applyPatch(to: checkoutable, config: config, logger: logger)
        }

        let repoBuildFolder = config.buildLocation(for: buildableItem)
        try? fileManager.removeItem(at: repoBuildFolder)
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        let timeMesurement = TimeMesurement()
        terminal.pushEphemeral()
        let stepNameText = "Configure \(buildableItem.name): ".consoleText(.plain)
        var status = "Configuring...".consoleText(ConsoleStyle(color: .blue))
        terminal.output(stepNameText + status)

        let repoFolder = buildableItem.sourceLocation(using: config)

        try fileManager.createFolderIfNotExists(at: config.buildsRootFolder)
        let repoBuildFolder = config.buildLocation(for: buildableItem)
        try fileManager.createEmptyFolder(at: repoBuildFolder)

        let cmakeCacheEntries = buildableItem.cmakeCacheEntries(config: config)

        let depCacheEntries: [String] = buildableItem.dependencies.flatMap { keyValue in
            let depName = keyValue.key
            let dep = keyValue.value
            return dep.cmakeDepDirCaheEntry(depName: depName, config: config)
        }

        let config = CMakeConfigure(folderUrl: repoFolder,
                                    cmakePath: config.cmakePath,
                                    buildFolder: repoBuildFolder,
                                    cacheEntries: cmakeCacheEntries + depCacheEntries,
                                    macOsTarget: config.macOsTarget,
                                    logger: logger)
        try await config.execute()

        terminal.popEphemeral()
        terminal.pushEphemeral()

        status = "Done".consoleText(ConsoleStyle(color: .green)) +  " in \(timeMesurement.durationString).".consoleText(.plain)
        terminal.output(stepNameText + status)
    }

    // MARK: Private

    private let buildableItem: BuildableItem
    private var fileManager: FileManager { FileManager.default }
    private let terminal = Terminal()
    private let defaultRevisionsMap = DefaultRevisionsMap()

    private func applyPatch(to checkoutable: Checkoutable, config: BuildConfig, logger: Logger) async throws {
        let patchesFolder = config.sourceRoot.appendingPathComponent("Patches", isDirectory: true)

        logger.info("Looking for patch named \(buildableItem.name) in \(patchesFolder.path)")

        let patches = try fileManager.contentsOfDirectory(atPath: patchesFolder.path)

        let desiredPatchFilename = buildableItem.name + ".patch"

        guard patches.contains(desiredPatchFilename) else {
            logger.info("There is no patch \(desiredPatchFilename)")
            return
        }

        let patchFileUrl = patchesFolder.appendingPathComponent(desiredPatchFilename, isDirectory: false)

        let repoFolder = config.location(for: checkoutable)
        let gitApply = ShellCommand("git", "apply", patchFileUrl.path, currentDirectoryURL: repoFolder, logger: logger)
        try await gitApply.execute()
    }
}
