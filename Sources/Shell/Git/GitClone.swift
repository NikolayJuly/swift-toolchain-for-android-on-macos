import Foundation
import Logging

public actor GitClone {
    /// - parameters:
    ///     - source: git repo url
    ///     - destination: folder URL
    ///     - logger: command output logger
    public init(source: URL, destination: URL, logger: Logger) {
        self.source = source
        self.destination = destination
        self.logger = logger
    }

    public func execute() async throws {
        let command = ShellCommand("git", "clone", "--progress", source.absoluteString, "\"\(destination.path)\"", logger: logger)
        _ = try await command.execute()
    }

    // MARK: Private

    private let source: URL
    private let destination: URL
    private let logger: Logger
}
