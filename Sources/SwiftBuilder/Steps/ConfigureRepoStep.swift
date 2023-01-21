import ConsoleKit
import Foundation
import Logging
import Shell

protocol ConfigurableRepoDependency {
    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String]
}

extension ConfigurableRepoDependency where Self: BuildableRepo {
    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String] {
        let depBuildUrl = config.buildLocation(for: self)
        let res = depName + "_DIR=\"\(depBuildUrl.path)/cmake/modules\""
        return [res]
    }
}

protocol ConfigurableRepo: Checkoutable {
    var cmakeCacheEntries: [String] { get }

    var buildSubfolder: String? { get }

    var dependencies: [String: ConfigurableRepoDependency] { get }
}

extension ConfigurableRepo {
    var cmakeCacheEntries: [String] { [] }

    var buildSubfolder: String? { nil }

    var dependencies: [String: ConfigurableRepoDependency] { [:] }
}

extension BuildConfig {
    func buildLocation(for repo: Checkoutable) -> URL {
        return buildsRootFolder.appendingPathComponent(repo.repoName, isDirectory: true)
    }
}

final class ConfigureRepoStep: BuildStep {

    var stepName: String {
        "configure-" + configurableRepo.repoName
    }

    init(configurableRepo: ConfigurableRepo) {
        self.configurableRepo = configurableRepo
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        let timeMesurement = TimeMesurement()
        terminal.pushEphemeral()
        let stepNameText = "Configure \(configurableRepo.repoName): ".consoleText(.plain)
        var status = "Configuring...".consoleText(ConsoleStyle(color: .blue))
        terminal.output(stepNameText + status)

        var repoFolder = config.location(for: configurableRepo)
        if let buildSubfolder = configurableRepo.buildSubfolder {
            repoFolder = repoFolder.appendingPathComponent(buildSubfolder, isDirectory: true)
        }

        try fileManager.createFolderIfNotExists(at: config.buildsRootFolder)
        let repoBuildFolder = config.buildLocation(for: configurableRepo)
        try fileManager.createEmptyFolder(at: repoBuildFolder)

        let depCacheEntries: [String] = configurableRepo.dependencies.flatMap { keyValue in
            let depName = keyValue.key
            let dep = keyValue.value
            return dep.cmakeDepDirCaheEntry(depName: depName, config: config)
        }

        let config = CMakeConfigure(folderUrl: repoFolder,
                                    cmakePath: config.cmakePath,
                                    buildFolder: repoBuildFolder,
                                    cacheEntries: configurableRepo.cmakeCacheEntries + depCacheEntries,
                                    logger: logger)
        try await config.execute()

        terminal.popEphemeral()
        terminal.pushEphemeral()

        status = "Done".consoleText(ConsoleStyle(color: .green)) +  " in \(timeMesurement.durationString).".consoleText(.plain)
        terminal.output(stepNameText + status)
    }

    // MARK: Private

    private let configurableRepo: ConfigurableRepo
    private var fileManager: FileManager { FileManager.default }
    private let terminal = Terminal()
}
