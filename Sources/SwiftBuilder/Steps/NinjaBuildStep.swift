import ConsoleKit
import Foundation
import Logging
import Shell

protocol BuildableRepo: Checkoutable {
    var targets: [String] { get }
}

extension BuildableRepo {
    // Most of repos has 1 default target
    var targets: [String] { [] }
}

final class NinjaBuildStep: BuildStep {
    var stepName: String {
        "build-" + buildableRepo.repoName
    }

    init(buildableRepo: BuildableRepo) {
        self.buildableRepo = buildableRepo
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        let timeMesurement = TimeMesurement()
        terminal.pushEphemeral()
        let stepNameText = "Build \(buildableRepo.repoName): ".consoleText(.plain)
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

    private let buildableRepo: BuildableRepo
    private let terminal = Terminal()
}
