import Foundation

extension Dictionary where Value: Comparable {

    @inlinable
    mutating func increase(to value: Value, for key: Key) {
        guard let existing = self[key] else {
            self[key] = value
            return
        }

        self[key] = Swift.max(existing, value)
    }
}
