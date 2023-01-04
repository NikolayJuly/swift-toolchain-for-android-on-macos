import Foundation
import Logging
import RegexBuilder

enum CheckoutRevision {
    case commit(String)
    case tag(String)

    /// default option, it will search hash in output of `utils/update-checkout`
    case parseFromUpdateCheckoutOuput
}

protocol Checkoutable {
    var githubUrl: String { get }

    var revision: CheckoutRevision { get }

    /// Will be used as folder name for checkout
    var repoName: String { get }
}

extension Checkoutable {
    var repoName: String {
        githubUrl.components(separatedBy: "/").last!.fileNameByRemovingExtension
    }

    var revision: CheckoutRevision {
        .parseFromUpdateCheckoutOuput
    }
}

/// This step will checkout all needed repos for the build
/// We will checkout few repos at the time, because this steps has fewer chances to fail
actor CheckoutStep: BuildStep {

    init(checkoutables: [Checkoutable]) {
        self.checkoutables = checkoutables
        statuses = [:]
        for checkoutable in checkoutables {
            statuses[checkoutable.repoName] = .starting
        }
        self.sortedKeys = statuses.keys.sorted()
    }

    func execute() async throws {
        // TODO: Implement actual checkout and check for existed repo
        // TODO: Implement reporing to terminal
        fatalError("Implement actual checkout")
    }

    // MARK: Private

    private let checkoutables: [Checkoutable]

    private var statuses: [String: Status]
    private let sortedKeys: [String]

    private let defaultRevisionsMap = DefaultRevisionsMap()

    fileprivate func update(status: Status, of checkoutable: Checkoutable) {
        statuses.increase(to: status, for: checkoutable.repoName)
    }
}

private enum Status: Comparable {
    case starting
    case receivingObjects(Double)
    case resolvingDeltas(Double)

    static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.starting, _):
            return true
        case (.receivingObjects, .starting):
            return false
        case let (.receivingObjects(l), .receivingObjects(r)):
            return l < r
        case (.receivingObjects, .resolvingDeltas):
            return true
        case let (.resolvingDeltas(l), .resolvingDeltas(r)):
            return l < r
        case (.resolvingDeltas,_):
            return false
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.starting, .starting):
            return true
        case let (.receivingObjects(l), .receivingObjects(r)):
            return abs(l - r) < 0.01
        case let (.resolvingDeltas(l), .resolvingDeltas(r)):
            return abs(l - r) < 0.01
        default:
            return false
        }
    }
}

private struct GitCheckoutStatusReceiver: LogHandler {

    weak var checkoutStep: CheckoutStep?
    let checkoutable: Checkoutable

    init(checkoutable: Checkoutable, checkoutStep: CheckoutStep) {
        self.checkoutable = checkoutable
        self.checkoutStep = checkoutStep
    }

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { self.metadata[key] }
        set { self.metadata[key] = newValue }
    }

    var metadata: Logger.Metadata = [:]

    var logLevel: Logger.Level = .info

    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt) {
        // We will try to parse few expected scenarios:
        // Receiving objects:   3% (3656/121866)
        // Receiving objects:   5% (6094/121866), 4.28 MiB | 8.41 MiB/s
        // Receiving objects: 100% (121866/121866), 52.47 MiB | 6.15 MiB/s, done.
        // Resolving deltas:   1% (635/63474)
        // Resolving deltas: 100% (63474/63474), done.
        let string = "\(message)"
        let receivingMatch = string.firstMatch(of: receivingObjectsRegex)
        let resolvingMatch = string.firstMatch(of: resolvingObjectsRegex)

        let receivingStatus: Status? = receivingMatch.map { .receivingObjects($0.output.1) }
        let resolvingStatus: Status? = resolvingMatch.map { .resolvingDeltas($0.output.1) }

        let newStatus = resolvingStatus ?? receivingStatus

        guard let newStatus else {
            return
        }

        Task {
            await checkoutStep?.update(status: newStatus, of: checkoutable)
        }
    }
}

private let receivingObjectsRegex = Regex {
    "Receiving objects:"
    OneOrMore(.whitespace)
    Capture {
        OneOrMore(.digit)
    } transform: { str -> Double in
        guard let digits = Double(str) else {
            throw "Failed to convert \(str) to Double"
        }
        return digits/100.0 as Double
    }
    "%"
    OneOrMore {
        .any
    }
}

private let resolvingObjectsRegex = Regex {
    "Resolving deltas:"
    OneOrMore(.whitespace)
    Capture {
        OneOrMore(.digit)
    } transform: { str -> Double in
        guard let digits = Double(str) else {
            throw "Failed to convert \(str) to Double"
        }
        return digits/100.0 as Double
    }
    "%"
    OneOrMore {
        .any
    }
}
