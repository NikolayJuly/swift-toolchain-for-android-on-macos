import AndroidConfig
import Foundation
import FoundationExtension
import HostConfig
import Logging
import Shell

final class RunBinaryInEmulatorStep: BuildStep {

    init() { }

    // MARK: BuildStep

    var stepName: String { "run-sample-binary-in-emulator" }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        let progressReporter = StepProgressReporter(step: "Run in emulator", initialState: .make)

        let compiledTestBinary = try await compileSampleAndroidBinary(config, logger: logger)

        let androidEmulator = try await AndroidEmulator(androidSdk: config.androidSdk,
                                                        logger: logger)
        try await androidEmulator.start()

        do {
            let adb = try await AndroidADB(androidSdk: config.androidSdk, logger: logger)
            try await waitTillDeviceAttached(String.emulatorName, adb: adb, logger: logger)

            try await adb.deleteBinPath()

            try await copyAllNeededLibs(config, adb: adb, logger: logger)

            try await adb.copy(compiledTestBinary)

            let testBinaryOutput = try await adb.run(compiledTestBinary.lastPathComponent)

            guard testBinaryOutput == "Hello world" else {
                throw SimpleError("Unexpected outup of test binary - \(testBinaryOutput). Expects \"Hello world\"")
            }

            logger.info("We did run test in emulator and got expected \"Hello world\"")
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

    /// Files in `symlinkFileMap.keys` will be copied, `symlinkFileMap.values` are way to add optional symlink with other name, because we need .so.65 in some cases
    private let toolchainLibs: [String] = [
        "libFoundation.so",
        "libswiftGlibc.so",
        "libswiftDispatch.so",
        "libdispatch.so",
        "libBlocksRuntime.so",
        "libswift_Concurrency.so",
        "libswiftCore.so",
        "libswiftSwiftOnoneSupport.so",
        "libicutu.so", "libicutu.so.65", "libicui18n.so.65.1",
        "libicutu.so", "libicutu.so.65", "libicui18n.so.65.1",
        "libicuuc.so", "libicuuc.so.65", "libicui18n.so.65.1",
        "libicudata.so", "libicudata.so.65", "libicui18n.so.65.1",
        "libicui18n.so", "libicui18n.so.65", "libicui18n.so.65.1",
    ]

    private let ndkFiles = ["libc++_shared.so"]

    private let arch = AndroidArchs.arm64

    private func copyAllNeededLibs(_ config: BuildConfig, adb: AndroidADB, logger: Logger) async throws {

        for filename in toolchainLibs {

            let sourceUrl = config.toolchainAndroidsLib(for: arch).appending(path: filename, directoryHint: .notDirectory)

            try await adb.copy(sourceUrl)
        }

        for ndkFile in ndkFiles {
            let sourceUrl = config.ndk.sysrootLib.appending(path: "\(arch.ndkLibArchName)/\(ndkFile)", directoryHint: .notDirectory)
            try await adb.copy(sourceUrl)
        }
    }

    private func compileSampleAndroidBinary(_ config: BuildConfig, logger: Logger) async throws -> URL {
        // this command allow to compile android binary

        let toolchainPath = config.toolchainRootFolder.path()
        let toolchainBinFolder = "\(toolchainPath)/usr/bin"

        let currentPath = ProcessInfo.processInfo.environment["PATH"] ?? ""

        let environment: [String: String] = [
            // needed to find "right" swift tools
            "PATH":"\(toolchainPath)/usr/bin:\(currentPath)",

            // These 2 needed, because swift package from toolchain doesn't work yet
            "SWIFT_EXEC_MANIFEST": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc",
            "SWIFT_EXEC": "\(toolchainPath)/usr/bin/swiftc-android",
        ]

        let swiftBinary = config.toolchainRootFolder.appending(path: "/usr/bin/swift", directoryHint: .notDirectory)

        let testAndroidBinaryName = "swift-on-android-test"

        let buildCommand = ExecuteBinaryCommand(swiftBinary,  "build",
                                                "--triple", arch.swiftTarget,
                                                "--product", testAndroidBinaryName,
                                                "--sdk", toolchainPath,
                                                "--toolchain", toolchainBinFolder,
                                                "-Xcc", "-I\(config.ndk.sysrootIncludePath)",
                                                "-Xcc", "-I\(config.ndk.sysrootIncludePath)/\(arch.ndkLibArchName)",
                                                currentDirectoryURL: config.sourceRoot,
                                                environment: environment,
                                                logger: logger)

        try await buildCommand.execute()

        let showPathCommand = ExecuteBinaryCommand(swiftBinary, "build",
                                                   "--triple", arch.swiftTarget,
                                                   "--show-bin-path",
                                                   currentDirectoryURL: config.sourceRoot,
                                                   logger: logger)
        let compiledBinariesPath = try await showPathCommand.execute()
        let compiledTestBinaryPath = "\(compiledBinariesPath)/\(testAndroidBinaryName)"
        return URL(filePath: compiledTestBinaryPath, directoryHint: .notDirectory)
    }

    private func waitTillDeviceAttached(_ device: String,
                                        timeout: TimeInterval = 20,
                                        adb: AndroidADB,
                                        logger: Logger) async throws {
        logger.info("Searching for attached device named \(device)")
        let startDate = Date()
        while Date.now.timeIntervalSince(startDate) < timeout {
            let devices = try await adb.listConnectedDevices()
            let neededOne = devices.first(where: { $0.contains(device) })
            if neededOne != nil {
                return
            }

            // no reason to run non stop - lets wait 0.5 sec
            try await Task.sleep(nanoseconds: 500_000_000)
        }

        throw SimpleError("Failed to find device \"\(device)\" in given time - \(Int(timeout))s")
    }
}
