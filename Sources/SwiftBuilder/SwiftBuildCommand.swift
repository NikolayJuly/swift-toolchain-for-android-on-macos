import ArgumentParser
import ConsoleKit
import FileLogging
import Foundation
import FoundationExtension
import HostConfig
import Logging
import Shell

struct BuildConfig {
    let workingFolder: URL
    let sourceRoot: URL

    var logsFolder: URL { workingFolder.appending(path: "logs", directoryHint: .isDirectory) }

    var buildsRootFolder: URL { workingFolder.appending(path: "build", directoryHint: .isDirectory) }

    var installRootFolder: URL { workingFolder.appending(path: "install", directoryHint: .isDirectory) }

    var toolchainRootFolder: URL { workingFolder.appending(path: "toolchain", directoryHint: .isDirectory) }

    // TODO: May be we need to make these value configurable
    let androidApiLevel: String = "21"

    // MARK: Android sdk

    let androidSdk: AndroidSDK

    var cmakePath: String { androidSdk.cmake.binFolder.path() }

    var cmakeToolchainFile: String {
        ndkPath + "/build/cmake/android.toolchain.cmake"
    }

    // MARK: NDK

    var ndkPath: String { androidSdk.ndk.folderUrl.path() }

    var ndkGccVersion: String { NDK.gccVersion }
    var ndkClangVersion: String { NDK.clangVersion }

    var ndkToolchain: String {
        androidSdk.ndk.toolchain.path()
    }

    // MARK: macOS

    let macOsTarget = "12.0" // deployment target
    let macOsArch = "arm64"
}

protocol BuildStep {

    var stepName: String { get }

    /// Some steps might have dependencies, where we might re-run step even if we completed it
    func shouldBeExecuted(_ completedSteps: [String]) -> Bool

    func execute(_ config: BuildConfig, logger: Logger) async throws
}

extension BuildStep {
    func shouldBeExecuted(_ completedSteps: [String]) -> Bool {
        let alreadyCompleted = completedSteps.contains(stepName)
        return !alreadyCompleted
    }
}

@main
final class SwiftBuildCommand: AsyncParsableCommand {

    @ArgumentParser.Option(name: .long,
                           help: "Folder which will contain all checkouts, logs and final artefacts",
                           transform: { URL(fileURLWithPath: $0, isDirectory: true) })
    var workingFolder: URL

    @ArgumentParser.Option(name: .long,
                           help: "Path to android SDK folder. This folder should contain `ndk` and `cmake` subfolder. Default installation path is - `/Users/$USER/Library/Android/sdk`",
                           transform: { try AndroidSDK(path: $0) })
    var androidSdk: AndroidSDK

    @ArgumentParser.Option(name: .long,
                           help: "Path to folder, containing package file",
                           transform: { URL(fileURLWithPath: $0, isDirectory: true) })
    var sourceRoot: URL

    func validate() throws {
        // I know that this function throw error, if failed to create needed folder
        try fileManager.createFolderIfNotExists(at: workingFolder)
    }

    func run() async throws {
        let terminal = Terminal()

        let timeMesurement = TimeMesurement()

        defer {
            let status = "Build ocmpleted in \(timeMesurement.durationString)".consoleText(.plain)
            terminal.output(status)
        }

        var buildProgress = try BuildProgress(withProgressIn: workingFolder)


        terminal.output("\n\nStart building process\n")

        let buildConfig = BuildConfig(workingFolder: workingFolder,
                                      sourceRoot: sourceRoot,
                                      androidSdk: androidSdk)

        try fileManager.createFolderIfNotExists(at: buildConfig.logsFolder)
        try fileManager.createFolderIfNotExists(at: buildConfig.buildsRootFolder)
        try fileManager.createFolderIfNotExists(at: buildConfig.installRootFolder)

        for i in 0..<steps.count {
            let step = steps[i]

            // Check - may be we already completed this step
            let shouldBeExecuted = step.shouldBeExecuted(buildProgress.completedSteps)

            guard shouldBeExecuted else {
                terminal.output("Skipping step \(step.stepName)")
                continue
            }

            let stepNumberString = String(format: "%03d", i+1)
            let logFileName = "Step-\(stepNumberString)-\(step.stepName).log"
            let logFileURL = buildConfig.logsFolder.appendingPathComponent(logFileName, isDirectory: false)
            try? fileManager.removeItem(at: logFileURL)
            let fileLogger = try FileLogging(to: logFileURL)
            let stepLogger = Logger(label: step.stepName) { label in
                fileLogger.handler(label: label)
            }

            stepLogger.info("Executing step \(type(of: step))")

            try await step.execute(buildConfig, logger: stepLogger)

            if buildProgress.completedSteps.contains(step.stepName) == false {
                buildProgress = buildProgress.updated(byAdding: step.stepName)
                try buildProgress.save(to: workingFolder)
            }
        }
    }

    // MARK: Private

    private var fileManager: FileManager { FileManager.default }

    private var steps: [BuildStep] { Self.steps }

    private static let steps: [BuildStep] = {
        let checkoutStep: BuildStep = CheckoutStep(checkoutables: Repos.checkoutOrder)

        let buildSteps: [BuildStep] = Builds.buildOrder.flatMap { $0.buildSteps() }

        let createToolchainStep = CreateToolchainStep(components: ToolchaninComponents.allComponents)

        return [checkoutStep] + buildSteps + [createToolchainStep]
    }()
}
