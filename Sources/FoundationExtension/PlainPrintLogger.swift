import Foundation
import Logging

public struct PlainPrintLogger: LogHandler {
    private let label: String

    public var logLevel: Logger.Level = .info

    public var metadata = Logger.Metadata()

    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }

    public init() {
        self.label = ""
    }

    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    source: String,
                    file: String,
                    function: String,
                    line: UInt) {
        guard self.logLevel <= level else {
            return
        }
        Swift.print(" " + message.description + " ")
    }
}
