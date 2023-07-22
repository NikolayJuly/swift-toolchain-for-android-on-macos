import Foundation

public struct CompositeError: CustomStringConvertible, LocalizedError {

    public init(_ errors: [Error], message: String = "", file: String = #file, line: Int = #line) {
        self.errors = errors
        self.message = message
        self.file = file
        self.line = line
    }

    public var errorDescription: String? {
        description
    }

    public var description: String {
        let messagePart = message.isEmpty ? "" : message + ".\n"
        let errorsPart = errors.map { $0.localizedDescription }.joined(separator: "\n")
        return "\(messagePart)Composite error from \(file):L\(line). Underlying errors:\n" + errorsPart
    }

    // MARK: Private

    private let errors: [Error]
    private let message: String
    private let file: String
    private let line: Int
}
