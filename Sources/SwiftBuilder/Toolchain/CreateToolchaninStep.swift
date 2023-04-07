import Foundation
import Logging

extension BuildConfig {
    var toolchainUsr: URL {
        toolchainRootFolder.appending(path: "usr/")
    }

    func toolchainAndroidsLib(for arch: AndroidArch) -> URL {
        toolchainRootFolder.appending(path: "usr/lib/swift/android/\(arch.swiftArch)/")
    }
}

final class CreateToolchaninStep: BuildStep {

    init(components: [ToolchaninComponent]) {
        self.components = components
    }

    // MARK: BuildStep

    var stepName: String { "create-toolchain" }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        let progressReporter = StepProgressReporter(step: "Create toolchain", initialState: .create)

        try createTopLevelFsStructure(config: config)

        progressReporter.update(state: .done)

        for component in components {
            try await component.copy(to: config.toolchainUsr, config: config, logger: logger)
        }

        throw "Error to avoid complete"
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
}

