import Foundation
import Logging

public actor GitClone {
    /// - parameters:
    ///     - source: git repo url
    ///     - destination: folder URL
    public init(source: URL, destination: URL) {
        self.source = source
        self.destination = destination
    }

    public func execute() async throws {
        let logger = Logger(label: "Git Checkout Logger") { _ in CloneLogger() }
        let command = ShellCommand("git", "clone", "--progress", source.absoluteString, destination.path, logger: logger)
        _ = try await command.execute()
    }

    // MARK: Private

    private let source: URL
    private let destination: URL
}

private struct CloneLogger: LogHandler {
    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { self.metadata[key] }
        set { self.metadata[key] = newValue }
    }
    
    var metadata: Logger.Metadata = [:]
    
    var logLevel: Logger.Level = .info

    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt) {
        print(message)
    }
}

