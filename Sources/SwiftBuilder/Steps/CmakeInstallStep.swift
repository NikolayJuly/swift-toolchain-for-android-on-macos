import Foundation
import Logging
import Shell

final class CmakeInstallStep: BuildStep {

    init(buildableItem: BuildableItem) {
        self.buildableItem = buildableItem
    }

    // MARK: BuildStep

    var stepName: String { "install-\(buildableItem.name)" }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        let progressReporter = StepProgressReporter(step: "Install \(buildableItem.name)", initialState: .install)

        let buildFolder = config.buildLocation(for: buildableItem)
        let installFolder = config.installLocation(for: buildableItem)

        let command = ShellCommand("DESTDIR=\(installFolder.path)", "cmake", "--build", buildFolder.path, "--target", "install",
                                   environment: ["PATH": config.cmakePath],
                                   logger: logger)
        try await command.execute()

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let buildableItem: BuildableItem
}
