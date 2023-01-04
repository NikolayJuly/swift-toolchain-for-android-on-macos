import Foundation

extension String: LocalizedError { }

extension String {
    /// Should be called on filename, not path. Will remove last '.ext'
    var fileNameByRemovingExtension: String {
        let components = self.components(separatedBy: ".")
        guard components.count > 1 else {
            return self
        }

        return components.prefix(components.count - 1).joined(separator: ".")
    }
}
