import AndroidConfig
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

        do {
            let adb = try await AndroidADB(androidSdk: config.androidSdk, logger: logger)
            try await copyAllNeededLibs(config, adb: adb, logger: logger)

        } catch {
            try? await androidEmulator.stop()
            throw error
        }

        try await androidEmulator.stop()

        progressReporter.update(state: .done)
    }

    // MARK: Private

    // TODO: We need to find the way not to depend on .so.65 files, and only depend on .so, then we can simplify it
    // TODO: Ideally we can actually make these map automatically.
    //       Use `objdump -x  <oaht_to_binary> | grep ‘R.*PATH’` - it will prent all needed files, and we can search thim in toolchain.
    //       And then check dependency of a dependency and repeat copy process.
    private let toolchainFileMap: [String: [String?]] = [
        "libFoundation.so": [nil],
        "libswiftGlibc.so": [nil],
        "libswiftDispatch.so": [nil],
        "libdispatch.so": [nil],
        "libBlocksRuntime.so": [nil],
        "libswift_Concurrency.so": [nil],
        "libswiftCore.so": [nil],
        "libswiftSwiftOnoneSupport.so": [nil],
        "libicutuswift.so": [nil, "libicutuswift.so.65"],
        "libicuucswift.so": [nil, "libicuucswift.so.65"],
        "libicudataswift.so": [nil, "libicudataswift.so.65"],
        "libicui18nswift.so": [nil, "libicui18nswift.so.65"],
    ]

    private let ndkFiles = ["libc++_shared.so"]

    private func copyAllNeededLibs(_ config: BuildConfig, adb: AndroidADB, logger: Logger) async throws {

        let arch = AndroidArchs.arm64

        for key in toolchainFileMap.keys {
            let toolchainLib = key
            let destinations = toolchainFileMap[key]!

            let sourceUrl = config.toolchainAndroidsLib(for: arch).appending(path: toolchainLib, directoryHint: .notDirectory)

            for destination in destinations {
                try await adb.copy(sourceUrl, filename: destination)
            }
        }

        for ndkFile in ndkFiles {
            let sourceUrl = config.ndk.sysrootLib.appending(path: "\(arch.ndkLibArchName)/\(ndkFile)", directoryHint: .notDirectory)
            try await adb.copy(sourceUrl)
        }
    }

    private func compileSampleAndroidBinary() {
    }
}
