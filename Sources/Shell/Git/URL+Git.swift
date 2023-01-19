import Foundation
import Logging

public extension URL {
    /// - note: return true if called on any subfolder of git repo
    func isGitRepo() async  -> Bool {
        let logger = Logger(label: "") { _ in
            return SilentLogHandler()
        }
        let command = ShellCommand("git", "-C", "\(path)", "rev-parse", logger: logger)
        do {
            try await command.execute()
            return true
        } catch {
            // We expect error with text "fatal: not a git repository (or any of the parent directories)" and exit statis - 128
            return false
        }
    }
}

private struct SilentLogHandler: LogHandler {
    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    var metadata: Logger.Metadata = [String: Logger.MetadataValue]()

    var logLevel: Logger.Level = .info

    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt) {}
}
