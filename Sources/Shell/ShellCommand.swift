import Foundation
import Logging

public enum ShellCommandError: Error {
    case nonZeroCode(Int32, String?, String?) // status code, error, output
}

/// - note: This actor execute commands, to execute script you need to delete`["-c", "-l"]` from `task.arguments`
public actor ShellCommand {

    /// - parameter command: command itself and arguments, , for example ShellCommand(["ls", "-la"], ..)
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
        let task = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()

        // If we have command part with space inside, but it is not wrapped with "", we will enforce it
        let wrappedCommand = command.map { commandPart in
            guard commandPart.contains(" ") else {
                return commandPart
            }

            guard commandPart.hasPrefix("\"") == false else {
                return commandPart
            }

            return "\"" + commandPart + "\""
        }

        let commandString = wrappedCommand.joined(separator: " ")
        logger.info("Executing command: \(commandString)")

        task.standardOutput = pipe
        task.standardError = errorPipe
        task.arguments = ["-c", "-l"] + [commandString]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.standardInput = nil

        if let currentDirectoryURL = currentDirectoryURL {
            task.currentDirectoryURL = currentDirectoryURL
        }

        if let environment = environment {
            task.environment = environment
        }

        let stdOutLines = AsyncBytesToLines()
        let errOutLines = AsyncBytesToLines()

        pipe.fileHandleForReading.readabilityHandler = { fileHandler in
            let availableData = fileHandler.availableData
            guard availableData.isEmpty == false else {
                return
            }

            stdOutLines.add(availableData)
        }

        errorPipe.fileHandleForReading.readabilityHandler = { fileHandler in
            let availableData = fileHandler.availableData
            guard availableData.isEmpty == false else {
                return
            }
            errOutLines.add(availableData)
        }

        let stdOutputTask = Task {
            for await line in stdOutLines {
                stdOut.append(line)
                logger.info("\(line)")
            }
        }

        let errorOutputTask = Task {
            for await line in errOutLines {
                errorOut.append(line)
                logger.error("\(line)")
            }
        }

        try task.run()

        await withCheckedContinuation { [task] continuation in
            task.asyncWait(continuation: continuation)
        }

        pipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil

        let restOfStdOut = try errorPipe.fileHandleForReading.readToEnd() ?? Data()
        stdOutLines.add(restOfStdOut)
        stdOutLines.complete()

        let restOfErrOut = try errorPipe.fileHandleForReading.readToEnd() ?? Data()
        errOutLines.add(restOfErrOut)
        errOutLines.complete()

        _ = await (stdOutputTask.result, errorOutputTask.result)

        let output = stdOut.joined(separator: "\n")

        guard task.terminationStatus == 0 else {
            let errorOutput = errorOut.joined(separator: "\n")
            throw ShellCommandError.nonZeroCode(task.terminationStatus, errorOutput, output)
        }

        return output
    }

    // MARK: Private

    private let command: [String]
    private let currentDirectoryURL: URL?
    private let environment: [String: String]?
    private let logger: Logger

    private var stdOut = [String]()
    private var errorOut = [String]()
}

private extension Process {
    // Hack to avoid warning "Capture of 'task' with non-sendable type 'Process' in a `@Sendable` closure"
    func asyncWait(continuation: CheckedContinuation<(), Never>) {
        DispatchQueue.global().async {
            self.waitUntilExit()
            continuation.resume()
        }
    }
}
