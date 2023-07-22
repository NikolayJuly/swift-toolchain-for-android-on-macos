import Foundation
import Logging
import Shell

struct SwiftcAndroidBuild: BuildableItem, ToolchaninComponent {

    // MARK: BuildableItem

    // Will be used as folder or file name part, where needed
    let name: String = "swiftc-android"

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.sourceRoot.appending(path: "Sources/SwiftcAndroid", directoryHint: .isDirectory)
    }

    func buildSteps() -> [BuildStep] {
        [
            SwiftcAndroidCompileStep(buildableItem: self),
            SwiftcAndroidInstallStep(buildableItem: self),
        ]
    }
}

private final class SwiftcAndroidCompileStep: BuildStep {

    init(buildableItem: BuildableItem) {
        self.buildableItem = buildableItem
    }

    // MARK: BuildStep

    let stepName: String = "build-swiftc-android"

    func execute(_ config: BuildConfig, logger: Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Build \(buildableItem.name)", initialState: .build)

        let buildFolder = config.buildLocation(for: buildableItem)
        try fileManager.createEmptyFolder(at: buildFolder)

        let commandParts: [String] = Self.swiftBuildCommand(buildFolder: buildFolder)

        let command = ShellCommand(commandParts,
                                   currentDirectoryURL: config.sourceRoot,
                                   logger: logger)
        try await command.execute()

        progressReporter.update(state: .done)
    }

    private let buildableItem: BuildableItem
    private var fileManager: FileManager { FileManager.default }

    fileprivate static func swiftBuildCommand(buildFolder: URL) -> [String] {
        [
            "swift", "build",
            "-c", "release",
            "-Xswiftc", "-g",
            "--product", .swiftcAndroidProductName,
            "--build-path", buildFolder.path(),
        ]
    }
}

private final class SwiftcAndroidInstallStep: BuildStep {
    init(buildableItem: BuildableItem) {
        self.buildableItem = buildableItem
    }

    // MARK: BuildStep

    let stepName: String = "install-swiftc-android"

    func execute(_ config: BuildConfig, logger: Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Install \(buildableItem.name)", initialState: .install)

        let buildFolder = config.buildLocation(for: buildableItem)
        let installFolder = config.installLocation(for: buildableItem)

        let showBinPathCommandParts = SwiftcAndroidCompileStep.swiftBuildCommand(buildFolder: buildFolder) + ["--show-bin-path"]
        let showBinPathCommand = ShellCommand(showBinPathCommandParts,
                                              currentDirectoryURL: config.sourceRoot,
                                              logger: logger)
        let sourceBinFolderPath = try await showBinPathCommand.execute()

        let destinationBinUrl = installFolder.appending(path: "bin", directoryHint: .notDirectory)

        try fileManager.createFolderIfNotExists(at: installFolder)
        try fileManager.createEmptyFolder(at: destinationBinUrl)

        let sourceBinFolder = URL(filePath: sourceBinFolderPath, directoryHint: .isDirectory)
        let sourceFile = sourceBinFolder.appending(path: String.swiftcAndroidProductName, directoryHint: .notDirectory)
        let destinationFile = destinationBinUrl.appending(path: String.swiftcAndroidProductName, directoryHint: .notDirectory)

        try fileManager.copyItem(at: sourceFile,
                                 to: destinationFile)

        progressReporter.update(state: .done)
    }

    private let buildableItem: BuildableItem
    private var fileManager: FileManager { FileManager.default }
}

private extension String {
    static let swiftcAndroidProductName = "swiftc-android"
}
