import Foundation

final class TimeMesurement {

    init() {}

    var duration: TimeInterval {
        return Date().timeIntervalSince(start)
    }

    var durationString: String {
        String(format: "%.1f", duration) + "s"
    }

    // MARK: Private

    private let start = Date()
}
