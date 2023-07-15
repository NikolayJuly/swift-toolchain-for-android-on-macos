import Foundation

public struct CompositeError: CustomStringConvertible, LocalizedError {

    public init(_ errors: [Error], file: String = #file, line: Int = #line) {
        self.errors = errors
        self.file = file
        self.line = line
    }

    public var errorDescription: String? {
        description
    }

    public var description: String {
        "Composite error from \(file):L\(line). Underlying errors:\n" + errors.map { $0.localizedDescription }.joined(separator: "\n")
    }

    // MARK: Private

    private let errors: [Error]
    private let file: String
    private let line: Int
}
