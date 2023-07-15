import Foundation

public struct SimpleError: CustomStringConvertible, LocalizedError {

    public init(_ description: String, file: String = #file, line: Int = #line) {
        self._description = description
        self.file = file
        self.line = line
    }

    public var errorDescription: String? {
        description
    }

    public var description: String {
        _description + " \(file):L\(line)"
    }

    // MARK: Private

    private let _description: String
    private let file: String
    private let line: Int
}
