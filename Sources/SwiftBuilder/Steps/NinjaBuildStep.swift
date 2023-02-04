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

    init(buildableRepo: BuildableItem) {
        self.buildableRepo = buildableRepo
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        let timeMesurement = TimeMesurement()
        terminal.pushEphemeral()
        let stepNameText = "Build \(buildableRepo.name): ".consoleText(.plain)
        var status = "Building...".consoleText(ConsoleStyle(color: .blue))
        terminal.output(stepNameText + status)

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

        terminal.popEphemeral()
        terminal.pushEphemeral()

        status = "Done".consoleText(ConsoleStyle(color: .green)) +  " in \(timeMesurement.durationString).".consoleText(.plain)
        terminal.output(stepNameText + status)
    }

    // MARK: Private

    private let buildableRepo: BuildableItem
    private let terminal = Terminal()
}
