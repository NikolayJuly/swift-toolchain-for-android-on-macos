import ArgumentParser
import ConsoleKit
import FileLogging
import Foundation
import Logging
import Shell

struct BuildConfig {
    let workingFolder: URL
    let sourceRoot: URL

    var logsFolder: URL { workingFolder.appendingPathComponent("logs", isDirectory: true) }

    var buildsRootFolder: URL { workingFolder.appendingPathComponent("build", isDirectory: true) }

    // MARK: CMAKE

    let cmakePath: String

    var cmakeToolchainFile: String {
        ndkPath + "/build/cmake/android.toolchain.cmake"
    }

    // MARK: NDK

    let ndkPath: String

    // TODO: May be we need to make these value configurable
    let androidApiLevel: String = "21"
    let ndkGccVersion: String = "4.9"
    let ndkClangVersion: String = "14.0.6"
    var ndkToolchain: String {
        ndkPath + "/toolchains/llvm/prebuilt/darwin-x86_64"
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
                           help: "Path to folder, which contains smake binary")
    var cmakePath: String

    @ArgumentParser.Option(name: .long,
                           help: "Path installed NDK, we expect v25 (25.1.8937393 exactly)")
    var ndkPath: String

    @ArgumentParser.Option(name: .long,
                           help: "Path to folder, containing package file",
                           transform: { URL(fileURLWithPath: $0, isDirectory: true) })
    var sourceRoot: URL

    func validate() throws {
        // I know that this function throw error, if failed to create needed folder
        try fileManager.createFolderIfNotExists(at: workingFolder)
    }

    func run() async throws {

        try validation()

        var buildProgress = try BuildProgress(withProgressIn: workingFolder)
        let terminal = Terminal()

        terminal.output("\n\nStart building process\n")

        let buildConfig = BuildConfig(workingFolder: workingFolder,
                                      sourceRoot: sourceRoot,
                                      cmakePath: cmakePath,
                                      ndkPath: ndkPath)

        try fileManager.createFolderIfNotExists(at: buildConfig.logsFolder)

        for i in 0..<steps.count {
            let step = steps[i]

            // Check - may be we already completed this step
            let shouldBeExecuted = step.shouldBeExecuted(buildProgress.completedSteps)

            guard shouldBeExecuted else {
                terminal.output("Skipping step \(step.stepName)")
                continue
            }

            let stepNumberString = String(format: "%02d", i+1)
            let logFileName = "Step-\(stepNumberString)-\(step.stepName).log"
            let logFileURL = buildConfig.logsFolder.appendingPathComponent(logFileName, isDirectory: false)
            try? fileManager.removeItem(at: logFileURL)
            let fileLogger = try FileLogging(to: logFileURL)
            let stepLogger = Logger(label: step.stepName) { label in
                fileLogger.handler(label: label)
            }

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

        let buildSteps: [BuildStep] = Repos.buildOrder.flatMap { repo -> [BuildStep] in
            let configure = ConfigureRepoStep(buildableItem: repo)
            let build = NinjaBuildStep(buildableRepo: repo)
            return [configure, build]
        }

        return [checkoutStep] + buildSteps
    }()

    private func validation() throws {
        let files = try fileManager.contentsOfDirectory(atPath: cmakePath)
        guard files.contains("cmake") else {
            throw "There is no `cmake` binary at \(cmakePath)"
        }

        guard files.contains("ninja") else {
            throw "There is no `ninja` binary at \(cmakePath)"
        }
    }
}
