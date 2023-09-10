import Foundation
import HostConfig
import Logging

final class RunBinaryInEmulatorStep: BuildStep {

    init() { }

    // MARK: BuildStep

    var stepName: String { "run-sample-binary-in-emulator" }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        let progressReporter = StepProgressReporter(step: "Run in emulator", initialState: .make)
        let androidEmulator = try await AndroidEmulator(androidSdk: config.androidSdk,
                                                        logger: logger)
        try await androidEmulator.start()
        try await androidEmulator.stop()
        progressReporter.update(state: .done)
    }
}
