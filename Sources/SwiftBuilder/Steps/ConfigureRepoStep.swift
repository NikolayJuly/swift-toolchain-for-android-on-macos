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

    var cmakeCacheEntries: [String] { get }

    var buildSubfolder: String? { get }

    var dependencies: [String: BuildableItemDependency] { get }

    var targets: [String] { get }

    func sourceLocation(using buildConfig: BuildConfig) -> URL
}

extension BuildableItem {
    var cmakeCacheEntries: [String] { [] }

    var buildSubfolder: String? { nil }

    var dependencies: [String: BuildableItemDependency] { [:] }

    // Most of repos has 1 default target
    var targets: [String] { [] }
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

        let depCacheEntries: [String] = buildableItem.dependencies.flatMap { keyValue in
            let depName = keyValue.key
            let dep = keyValue.value
            return dep.cmakeDepDirCaheEntry(depName: depName, config: config)
        }

        let config = CMakeConfigure(folderUrl: repoFolder,
                                    cmakePath: config.cmakePath,
                                    buildFolder: repoBuildFolder,
                                    cacheEntries: buildableItem.cmakeCacheEntries + depCacheEntries,
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
}
