import Foundation
import FoundationExtension
import HostConfig
import Logging
import Shell

extension String {
    static let emulatorPrt: String = "5566"
}

actor AndroidEmulator {
    // TODO: Later we can add support for [avdmanager](https://developer.android.com/tools/avdmanager), but it require java runtime
    /// On init, we will try to find expected emulator - Pixel 6
    init(androidSdk: AndroidSDK,
         logger: Logger) async throws {
        self.androidSdk = androidSdk
        self.logger = logger

        let emulatorBinaryUrl = androidSdk.sdkRootUrl.appending(path: "emulator/emulator", directoryHint: .notDirectory)
        let listEmulators = ExecuteBinaryCommand(emulatorBinaryUrl, "-list-avds", logger: logger)
        let ourtput = try await listEmulators.execute()
        let emulatorsList = ourtput.components(separatedBy: "\n")
        guard let pixel6Avd = emulatorsList.first(where: { $0.hasPrefix("Pixel_6") }) else {
            throw SimpleError("Failed to find AVD with \"Pixel_6\" prefix")
        }

        self.avdName = pixel6Avd
        self.emulatorBinaryUrl = emulatorBinaryUrl
    }

    func start() async throws {
        guard case .notRunning = state else {
            throw SimpleError("We can't start in current state - \(state)")
        }

        let runEmulator = ExecuteBinaryCommand(emulatorBinaryUrl,
                                               "-avd", avdName,
                                               "-netdelay", "none",
                                               "-netspeed", "full",
                                               "-no-audio",
                                               "-no-window",
                                               "-id", "swift_test",
                                               "-port", .emulatorPrt,
                                               logger: logger)


        Task {
            do {
                try await runEmulator.execute()
            } catch {
                switch state {
                case let .stopping(continuation):
                    logger.error("Did stop emulator")
                    continuation.resume()
                    break
                case .running, .notRunning:
                    logger.error("Did catch exception during execution - \(error)")
                }
            }

            self.state = .notRunning
        }

        // I know that it takes time to start emulator, so lets just wait for 1 sec
        try await Task.sleep(for: .seconds(1))

        self.state = .running(runEmulator)
    }

    func stop() async throws {
        guard case let .running(command) = state else {
            throw SimpleError("We can't stop in current state - \(state)")
        }

        await withCheckedContinuation { continuation in
            self.state = .stopping(continuation)
            command.terminate()
        }
    }

    // MARK: Private

    private enum State: CustomStringConvertible {
        case notRunning
        case running(ExecuteBinaryCommand)
        case stopping(CheckedContinuation<Void, Never>)

        var description: String {
            switch self {
            case .notRunning:
                return "State.notRunning"
            case .running:
                return "State.running"
            case .stopping:
                return "State.stopping"
            }
        }
    }

    private let androidSdk: AndroidSDK
    private let logger: Logger

    private let avdName: String
    private let emulatorBinaryUrl: URL

    private var state: State = .notRunning
}
