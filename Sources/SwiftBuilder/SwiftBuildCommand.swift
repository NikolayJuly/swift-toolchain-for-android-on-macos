import ArgumentParser
import FileLogging
import Foundation
import Logging
import Shell

struct BuildConfig {
    let workingFolder: URL

    let cmakePath: String

    var logsFolder: URL { workingFolder.appendingPathComponent("logs", isDirectory: true) }

    var buildsRootFolder: URL { workingFolder.appendingPathComponent("build", isDirectory: true) }
}

protocol BuildStep {

    var stepName: String { get }

    func execute(_ config: BuildConfig, logger: Logger) async throws
}

@main
final class SwiftBuildCommand: AsyncParsableCommand {

    @Option(name: .long,
            help: "Folder which will contain all checkouts, logs and final artefacts",
            transform: { URL(fileURLWithPath: $0, isDirectory: true) })
    var workingFolder: URL

    @Option(name: .long,
            help: "Path to folder, which contains smake binary")
    var cmakePath: String

    func validate() throws {
        // I know that this function throw error, if failed to create needed folder
        try fileManager.createFolderIfNotExists(at: workingFolder)
    }

    func run() async throws {

        try validation()

        let buildConfig = BuildConfig(workingFolder: workingFolder, cmakePath: cmakePath)

        try fileManager.createFolderIfNotExists(at: buildConfig.logsFolder)

        for i in 0..<steps.count {
            let step = steps[i]
            let stepNumberString = String(format: "%02d", i+1)
            let logFileName = "Step-\(stepNumberString)-\(step.stepName).log"
            let logFileURL = buildConfig.logsFolder.appendingPathComponent(logFileName, isDirectory: false)
            try? fileManager.removeItem(at: logFileURL)
            let fileLogger = try FileLogging(to: logFileURL)
            let stepLogger = Logger(label: step.stepName) { label in
                fileLogger.handler(label: label)
            }

            try await step.execute(buildConfig, logger: stepLogger)
        }
    }

    // MARK: Private

    private var fileManager: FileManager { FileManager.default }

    private var steps: [BuildStep] { Self.steps }

    private static let steps: [BuildStep] = {
        let checkoutStep: BuildStep = CheckoutStep(checkoutables: Repos.checkoutOrder)

        let buildSteps: [BuildStep] = Repos.buildOrder.flatMap { repo -> [BuildStep] in
            let configure = ConfigureRepoStep(configurableRepo: repo)
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

private extension String {
    static let cmakePathEnvKey = "CMAKE_PATH"
}
