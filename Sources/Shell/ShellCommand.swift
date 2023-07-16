import Foundation
import Logging

public enum ShellCommandError: Error {
    case nonZeroCode(Int32, String?, String?) // status code, error, output
}

/// - note: This class execute commands, to execute script you need only`["-l"]` in `task.arguments`, so remove "-c"
public final class ShellCommand {

    /// - parameter command: command itself and arguments, for example ShellCommand(["ls", "-la"], ..)
    public init(_ command: [String],
                currentDirectoryURL: URL? = nil,
                environment: [String: String]? = nil,
                logger: Logger) {
        self.command = command
        self.currentDirectoryURL = currentDirectoryURL
        self.environment = environment
        self.logger = logger
    }

    /// - parameter command: command itself and arguments, for example ShellCommand("ls", "-la", ...)
    public init(_ command: String ...,
                currentDirectoryURL: URL? = nil,
                environment: [String: String]? = nil,
                logger: Logger) {
        self.command = command
        self.currentDirectoryURL = currentDirectoryURL
        self.environment = environment
        self.logger = logger
    }

    /// If no output - empty srting will be returned
    @discardableResult
    public func execute() async throws -> String {
        let commandString = command.joined(separator: " ")
        let command = ExecuteBinaryCommand(URL(fileURLWithPath: "/bin/zsh"),
                                           ["-c", "-l"] + [commandString],
                                           currentDirectoryURL: currentDirectoryURL,
                                           environment: environment,
                                           logger: logger)

        return try await command.execute()
    }

    // MARK: Private

    private let command: [String]
    private let currentDirectoryURL: URL?
    private let environment: [String: String]?
    private let logger: Logger

    private let lock = NSLock()
    private var didCompleteTask = false

    private var stdOut = [String]()
    private var errorOut = [String]()
}

