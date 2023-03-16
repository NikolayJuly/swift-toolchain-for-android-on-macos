import Foundation
import Logging
import Shell

final class ConfigureRepoStep: BuildStep {
    var stepName: String {
        "configure-" + buildableItem.name
    }

    init(buildableItem: NinjaBuildableItem) {
        self.buildableItem = buildableItem
    }

    func shouldBeExecuted(_ completedSteps: [String]) -> Bool {
        // if build failed, we might want ro re-run configure, because we might change smake cache to fix it
        let buildStepName = NinjaBuildStep.buildStepName(for: buildableItem)
        let buildAlreadyCompleted = completedSteps.contains(buildStepName)
        return !buildAlreadyCompleted
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        let progressReporter = StepProgressReporter(step: "Configure \(buildableItem.name)", initialState: .configure)

        try await prepare(config, logger: logger)

        let repoFolder = buildableItem.sourceLocation(using: config)

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

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let buildableItem: NinjaBuildableItem
    private var fileManager: FileManager { FileManager.default }
    private let defaultRevisionsMap = DefaultRevisionsMap()

    private func applyPatch(to repo: BuildableItemRepo, config: BuildConfig, logger: Logger) async throws {
        let checkoutable = repo.checkoutable

        logger.info("Checking for a patch for \(repo.patchFileName)")

        let patchesFolder = config.sourceRoot.appendingPathComponent("Patches", isDirectory: true)

        logger.info("Looking for patch named \(buildableItem.name) in \(patchesFolder.path)")

        let patches = try fileManager.contentsOfDirectory(atPath: patchesFolder.path)

        guard patches.contains(repo.patchFileName) else {
            logger.info("There is no patch \(repo.patchFileName)")
            return
        }

        let patchFileUrl = patchesFolder.appendingPathComponent(repo.patchFileName, isDirectory: false)

        let repoFolder = config.location(for: checkoutable)
        let gitApply = ShellCommand("git", "apply", patchFileUrl.path, currentDirectoryURL: repoFolder, logger: logger)
        try await gitApply.execute()
    }

    private func prepare(_ config: BuildConfig, logger: Logging.Logger) async throws {
        // I would prefer don't have secret check for other protocol, but looks like simplest solution for now
        if let underlyingRepo = buildableItem.underlyingRepo {
            let checkoutable = underlyingRepo.checkoutable
            logger.info("Step has git repo, so executing git reset to needed revision before build")
            let object: String = try checkoutable.checkoutObject(using: self.defaultRevisionsMap)
            let repoFolder = config.location(for: checkoutable)
            let gitReset = GitReset(repoUrl: repoFolder, object: object, logger: logger)
            try await gitReset.execute()

            try await applyPatch(to: underlyingRepo, config: config, logger: logger)
        }

        let repoBuildFolder = config.buildLocation(for: buildableItem)
        try? fileManager.removeItem(at: repoBuildFolder)
    }

}
