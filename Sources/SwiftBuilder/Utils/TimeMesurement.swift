import Foundation

final class TimeMesurement {

    init() {}

    var duration: TimeInterval {
        return Date().timeIntervalSince(start)
    }

    var durationString: String {
        switch duration {
        case 60..<60*60:
            let seconds = Int(duration)
            return String(format: "%02dm%02ds", seconds/60, seconds%60)
        case 60.0*60.0..<24*60*60:
            let intSeconds = Int(duration)
            let hours = intSeconds/(60*60)
            let minutes = (intSeconds % (60*60))/60
            let seconds = intSeconds % 60
            return String(format: "%02dh%02dm%02ds", hours, minutes, seconds)
        default:
            return String(format: "%.1fs", duration)
        }
    }

    // MARK: Private

    private let start = Date()
}
