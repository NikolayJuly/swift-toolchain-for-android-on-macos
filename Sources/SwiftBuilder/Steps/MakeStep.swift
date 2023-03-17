import Foundation
import Logging
import Shell

final class MakeStep: BuildStep {
    var stepName: String { "make-\(buildableItem.name)" }

    init(buildableItem: BuildableItem,
         makeArgs: [String] = []) {
        self.buildableItem = buildableItem
        self.makeArgs = makeArgs
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Build \(buildableItem.name)", initialState: .build)

        let buildFolderUrl = config.buildLocation(for: buildableItem)
        let command = ShellCommand(["make"] + makeArgs,
                                   currentDirectoryURL: buildFolderUrl,
                                   environment: ["PATH": "\(config.ndkToolchain)/bin"],
                                   logger: logger)
        try await command.execute()

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let buildableItem: BuildableItem
    private let makeArgs: [String]
}

final class MakeInstallStep: BuildStep {
    var stepName: String { "install-\(buildableItem.name)" }

    init(buildableItem: BuildableItem,
         makeArgs: [String] = ["install"]) {
        self.buildableItem = buildableItem
        self.makeArgs = makeArgs
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Install \(buildableItem.name)", initialState: .install)

        let buildFolderUrl = config.buildLocation(for: buildableItem)
        let command = ShellCommand(["make"] + makeArgs,
                                   currentDirectoryURL: buildFolderUrl,
                                   logger: logger)
        try await command.execute()

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let buildableItem: BuildableItem
    private let makeArgs: [String]
}
