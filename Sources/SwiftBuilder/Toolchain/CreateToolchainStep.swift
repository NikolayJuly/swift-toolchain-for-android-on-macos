import AndroidConfig
import Foundation
import Logging
import Shell

extension BuildConfig {
    var toolchainUsr: URL {
        toolchainRootFolder.appending(path: "usr/")
    }

    func toolchainAndroidsLib(for arch: AndroidArch) -> URL {
        toolchainRootFolder.appending(path: "usr/lib/swift/android/\(arch.swiftArch)/")
    }
}

final class CreateToolchainStep: BuildStep {

    init(components: [ToolchaninComponent]) {
        self.components = components
    }

    // MARK: BuildStep

    var stepName: String { "create-toolchain" }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        let progressReporter = StepProgressReporter(step: "Create toolchain", initialState: .create)

        try createTopLevelFsStructure(config: config)

        for component in components {
            try await component.copy(to: config.toolchainUsr, config: config, logger: logger)
        }

        try await createSymlinkForDylibs(config: config, logger: logger)

        try copyLicences(config: config)

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private var fileManager: FileManager { .default }
    private let components: [ToolchaninComponent]

    private func createTopLevelFsStructure(config: BuildConfig) throws {
        try fileManager.createEmptyFolder(at: config.toolchainRootFolder)
        try fileManager.createEmptyFolder(at: config.toolchainUsr)
        let licenseFilename = "LICENSE.txt"
        try fileManager.copyItem(at: config.sourceRoot.appending(path: licenseFilename, directoryHint: .notDirectory),
                                 to: config.toolchainRootFolder.appending(path: licenseFilename, directoryHint: .notDirectory))

        let ndkVersion = URL(filePath: config.ndkPath, directoryHint: .isDirectory).lastPathComponent
        let ndkVersionData = ndkVersion.data(using: .utf8)!
        let ndkVersionFile = config.toolchainRootFolder.appending(path: "NDK_VERSION", directoryHint: .notDirectory)
        try ndkVersionData.write(to: ndkVersionFile)
    }

    private func createSymlinkForDylibs(config: BuildConfig, logger: Logger) async throws {
        logger.info("Creating symlinks for libs in usr/lib/swift/macosx")
        // We habe few libs in `usr/lib/swift/macosx`, but we ned them in `usr/lib/` for linkage
        let libsFolder = config.toolchainUsr.appending(path: "lib/")
        let macosLibsFolder = config.toolchainUsr.appending(path: "lib/swift/macosx/")
        let dylibLibs = try fileManager.categorizedFolderContent(at: macosLibsFolder).files.filter { $0.pathExtension == "dylib" }
        for dylibLib in dylibLibs {
            let command = ShellCommand("ln", "-svf", "./swift/macosx/" + dylibLib.lastPathComponent,
                                       currentDirectoryURL: libsFolder,
                                       logger: logger)
            try await command.execute()
        }
    }

    private func copyLicences(config: BuildConfig) throws {
        let destinationRoot = config.toolchainUsr.appending(path: "share")
        try fileManager.createFolderIfNotExists(at: destinationRoot)

        for repo in Repos.checkoutOrder {
            let paths = try repo.licencies(config: config)
            let repoUrl = config.location(for: repo)
            for path in paths {

                let source = repoUrl.appending(path: path)

                let allPathComponents = [repo.repoName] + path.components(separatedBy: "/")
                let folders = Array(allPathComponents.dropLast())

                let createdFolder = try fileManager.createPathSubfolders(for: folders, root: destinationRoot)

                let destination = createdFolder.appendingPathComponent(allPathComponents.last!)

                let alreadyExists = fileManager.fileExists(at: destination)
                guard !alreadyExists else {
                    continue
                }
                
                try fileManager.copyItem(at: source, to: destination)
            }
        }
    }
}

private extension FileManager {
    func createPathSubfolders(for folders: [String], root: URL) throws -> URL {
        let fileManager: FileManager = .default
        var currentFolder = root
        for folder in folders {
            currentFolder = currentFolder.appending(path: folder, directoryHint: .isDirectory)
            try fileManager.createFolderIfNotExists(at: currentFolder)
        }
        return currentFolder
    }
}


