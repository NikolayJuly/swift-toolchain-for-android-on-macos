import ConsoleKit
import Foundation
import Logging
import Shell

final class NinjaBuildStep: BuildStep {

    static func buildStepName(for buildableRepo: BuildableItem) -> String {
        "build-" + buildableRepo.name
    }

    var stepName: String {
        Self.buildStepName(for: buildableRepo)
    }

    init(buildableRepo: NinjaBuildableItem) {
        self.buildableRepo = buildableRepo
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        let progressReporter = StepProgressReporter(step: "Build \(buildableRepo.name)", initialState: .build)

        let repoBuildFolder = config.buildLocation(for: buildableRepo)

        let commandParths: [String] = [
            "ninja",
            "-C", repoBuildFolder.path,
            "-j5", // max 5 jobs in parallel
        ] + buildableRepo.targets

        let command = ShellCommand(commandParths,
                                   environment: ["PATH": config.cmakePath],
                                   logger: logger)
        try await command.execute()

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let buildableRepo: NinjaBuildableItem
}
