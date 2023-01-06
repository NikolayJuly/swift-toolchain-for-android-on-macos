import ArgumentParser
import FileLogging
import Foundation
import Logging
import Shell

struct BuildConfig {
    let workingFolder: URL

    var logsFolder: URL { workingFolder.appendingPathComponent("logs", isDirectory: true) }
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

    func validate() throws {
        // I know that this function throw error, if failed to create needed folder
        try fileManager.createFolderIfNotExists(at: workingFolder)
    }

    func run() async throws {

        let buildConfig = BuildConfig(workingFolder: workingFolder)

        try fileManager.createFolderIfNotExists(at: buildConfig.logsFolder)

        for i in 0..<steps.count {
            let step = steps[i]
            let stepNumberString = String(format: "%02d", i+1)
            let logFileName = "Step-\(stepNumberString)-\(step.stepName).log"
            let logFileURL = buildConfig.logsFolder.appendingPathComponent(logFileName, isDirectory: false)
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

    private static let steps: [BuildStep] = [
        CheckoutStep(checkoutables: Repos.allRepos),
    ]
}
