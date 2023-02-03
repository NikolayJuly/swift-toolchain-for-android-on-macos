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
        let task = Process()

        let pipe = Pipe()
        let errorPipe = Pipe()

        let commandString = command.joined(separator: " ")
        if let currentDirectoryURL {
            logger.info("Executing command in directory: \(currentDirectoryURL.path)")
        }
        if let environment {
            logger.info("Command environment:\n\(environment.map { $0.key + ":" + $0.value }.joined(separator: "\n"))")
        }
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
            self.lock.lock()
            defer { self.lock.unlock() }
            guard !self.didCompleteTask else {
                // We might have race condition, where we will `readToTheEnd()` and complete async bytes, when this block called with non empty data somehow
                return
            }
            let availableData = fileHandler.availableData
            guard availableData.isEmpty == false else {
                return
            }
            stdOutLines.add(availableData)
        }

        errorPipe.fileHandleForReading.readabilityHandler = { fileHandler in
            self.lock.lock()
            defer { self.lock.unlock() }
            guard !self.didCompleteTask else {
                // We might have race condition, where we will `readToTheEnd()` and complete async bytes, when this block called with non empty data somehow
                return
            }
            let availableData = fileHandler.availableData
            guard availableData.isEmpty == false else {
                return
            }
            errOutLines.add(availableData)
        }

        let stdOutputTask = Task {
            for await line in stdOutLines {
                guard line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                    continue
                }
                stdOut.append(line)
                logger.info("\(line)")
            }
        }

        let errorOutputTask = Task {
            for await line in errOutLines {
                guard line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                    continue
                }
                errorOut.append(line)
                logger.error("\(line)")
            }
        }

        await withCheckedContinuation { [task] continuation in
            task.terminationHandler = { _ in
                continuation.resume()
            }

            do {
                try task.run()
            } catch let exc {
                logger.error("Failed to run task with error - \(exc)")
            }
        }

        lock.withLock {
            self.didCompleteTask = true
            pipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil

            if let restOfStdOut = try? errorPipe.fileHandleForReading.readToEnd() {
                stdOutLines.add(restOfStdOut)
            }
            stdOutLines.complete()

            if let restOfErrOut = try? errorPipe.fileHandleForReading.readToEnd() {
                errOutLines.add(restOfErrOut)
            }

            errOutLines.complete()
        }

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

    private let lock = NSLock()
    private var didCompleteTask = false

    private var stdOut = [String]()
    private var errorOut = [String]()
}

