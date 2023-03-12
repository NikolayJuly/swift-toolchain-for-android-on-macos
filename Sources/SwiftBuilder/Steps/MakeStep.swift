import Foundation
import Logging
import Shell

final class MakeStep: BuildStep {
    var stepName: String { "make-\(buildableItem.name)" }

    init(buildableItem: BuildableItem) {
        self.buildableItem = buildableItem
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Make \(buildableItem.name)", initialState: .make)

        let buildFolderUrl = config.buildLocation(for: buildableItem)
        let command = ShellCommand(["make"],
                                   currentDirectoryURL: buildFolderUrl,
                                   logger: logger)
        try await command.execute()

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let buildableItem: BuildableItem
}
