import Foundation
import Logging

/// Rest repo to desired state
public actor GitReset {
    /// - parameters:
    ///     - repoUrl: URL to local git repo
    ///     - object: branch name or commit hash
    ///     - logger: command output logger
    public init(repoUrl: URL, object: String, logger: Logger) {
        self.repoUrl = repoUrl
        self.object = object
        self.logger = logger
    }

    public func execute() async throws {
        let clean = ShellCommand("git", "clean", "-f",
                                 currentDirectoryURL: repoUrl,
                                 logger: logger)
        _ = try await clean.execute()

        let reset = ShellCommand("git", "reset", "--hard", object,
                                   currentDirectoryURL: repoUrl,
                                   logger: logger)
        _ = try await reset.execute()
    }

    // MARK: Private

    private let repoUrl: URL
    private let object: String
    private let logger: Logger
}
