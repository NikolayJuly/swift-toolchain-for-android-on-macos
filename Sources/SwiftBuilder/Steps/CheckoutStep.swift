import ConsoleKit
import FileLogging
import Foundation
import Logging
import RegexBuilder
import Shell
import WorkPoolDraning

enum CheckoutRevision: Equatable {
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

extension BuildConfig {
    func location(for checkoutable: Checkoutable) -> URL {
        return workingFolder.appendingPathComponent(checkoutable.repoName, isDirectory: true)
    }
}

/// This step will checkout all needed repos for the build
/// We will checkout few repos at the time, because this steps has fewer chances to fail
actor CheckoutStep: BuildStep {

    let stepName: String = "Checkout"

    init(checkoutables: [Checkoutable]) {
        self.checkoutables = checkoutables
        statuses = [:]
        for checkoutable in checkoutables {
            statuses[checkoutable.repoName] = .wairing
        }

        self.repoNameMaxLength = checkoutables.map { $0.repoName.count }.max() ?? 5
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        typealias Drainer = StaticAsyncWorkPoolDrainer<Checkoutable, Void>

        let timeMesurement = TimeMesurement()

        try fileManager.createFolderIfNotExists(at: config.logsFolder)

        logger.info("Start working on checkout. We have \(checkoutables.count) repos to work on")

        terminal.pushEphemeral()
        printCurrentCheckoutStatus()

        let workPoolDrainer = Drainer(stack: checkoutables,
                                      maxConcurrentOperationCount: 5) { checkoutable in

            self.statuses[checkoutable.repoName] = .fetching
            do {
                let repoFolder = config.location(for: checkoutable)
                let isExistedRepo = await repoFolder.isGitRepo()

                if !isExistedRepo {
                    try await self.clone(checkoutable, config: config, logger: logger)
                }

                var revision = checkoutable.revision
                if revision == .parseFromUpdateCheckoutOuput {
                    guard let defaultRevision = self.defaultRevisionsMap[checkoutable.repoName] else {
                        throw "No default revision for \(checkoutable.repoName)"
                    }
                    revision = defaultRevision
                }

                let object: String
                switch revision {
                case let .commit(hash):
                    object = hash
                case let .tag(tag):
                    object = tag
                case .parseFromUpdateCheckoutOuput:
                    throw "Unepected value of revision for \(checkoutable.repoName)"
                }

                logger.info("Checking out \(object) in \(checkoutable.repoName)")

                let gitReset = GitReset(repoUrl: repoFolder, object: object, logger: logger)

                try await gitReset.execute()

                logger.info("Did checkout \(object) in \(checkoutable.repoName)")

                self.statuses[checkoutable.repoName] = .success
            } catch let exc {
                self.statuses[checkoutable.repoName] = .failied
                throw exc
            }
        }

        try await workPoolDrainer.wait()

        terminal.output("Checkout complete in \(timeMesurement.durationString)")
    }

    // MARK: Private

    private let checkoutables: [Checkoutable]

    private var statuses: [String: Status] {
        didSet {
            printCurrentCheckoutStatus()
        }
    }

    private let repoNameMaxLength: Int

    private let defaultRevisionsMap = DefaultRevisionsMap()
    private let fileManager: FileManager = .default
    private let terminal = Terminal()

    fileprivate func update(status: Status, of checkoutable: Checkoutable) {
        statuses.increase(to: status, for: checkoutable.repoName)
    }

    private func clone(_ checkoutable: Checkoutable, config: BuildConfig, logger: Logger) async throws {
        let sourceUrl = URL(string: checkoutable.githubUrl)!
        let destination = config.location(for: checkoutable)

        let logFileName = "git-clone-\(checkoutable.repoName).log"
        let logFileURL = config.logsFolder.appendingPathComponent(logFileName, isDirectory: false)

        logger.info("Start clonning \(checkoutable.repoName). Log at \(logFileURL.path)")

        let fileLogger = try FileLogging(to: logFileURL)

        let cloneLogger = Logger(label: checkoutable.repoName) { label in
            fileLogger.handler(label: label)
        }

        let gitClone = GitClone(source: sourceUrl, destination: destination, logger: cloneLogger)
        do {
            try await gitClone.execute()
        } catch let exc {
            logger.error("Failed git clone of \(checkoutable.repoName). Error - \(exc)")
            throw exc
        }
    }

    private func printCurrentCheckoutStatus() {
        terminal.popEphemeral()
        terminal.pushEphemeral()

        terminal.output("Checkout:")

        for checkoutable in checkoutables {
            // Values of maps created on init with some value, and I never nil them
            // To simplify logic, I will use `!`
            let status = statuses[checkoutable.repoName]!
            let statusText: ConsoleText
            switch status {
            case .wairing:
                statusText = "waiting".consoleText(ConsoleStyle(color: .yellow))
            case .fetching:
                statusText = "fetching".consoleText(ConsoleStyle(color: .blue))
            case .success:
                statusText = "success".consoleText(.success)
            case .failied:
                statusText = "failed".consoleText(.error)
            }

            let repoName = checkoutable.repoName.padding(toLength: repoNameMaxLength, withPad: " ", startingAt: 0)
            let title = (repoName + " - ").consoleText(.plain)
            terminal.output(title + statusText)
        }
    }
}

private enum Status: Comparable {
    case wairing
    case fetching
    case success
    case failied
}
