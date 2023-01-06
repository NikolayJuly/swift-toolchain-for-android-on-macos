import Foundation

extension Dictionary where Value: Comparable {

    /// If `value` less than `self[key]` - do nothing, discarding `value`
    /// `nil` smaller than any `value`
    @inlinable
    mutating func increase(to value: Value, for key: Key) {
        guard let existing = self[key] else {
            self[key] = value
            return
        }

        self[key] = Swift.max(existing, value)
    }
}
