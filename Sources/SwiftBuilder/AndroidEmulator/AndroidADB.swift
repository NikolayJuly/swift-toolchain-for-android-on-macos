import Foundation
import FoundationExtension
import HostConfig
import Logging
import Shell

final class AndroidADB {
    init(androidSdk: AndroidSDK,
         logger: Logger) async throws {
        self.androidSdk = androidSdk
        self.logger = logger

        self.adbBinaryUrl = androidSdk.sdkRootUrl.appending(path: "platform-tools/adb", directoryHint: .notDirectory)

        // Lets make sure it is running
        let command = ExecuteBinaryCommand(adbBinaryUrl, "start-server",
                                           logger: logger)
        try await command.execute()
    }

    func deleteBinPath() async throws {
        let coomand = ExecuteBinaryCommand(adbBinaryUrl,
                                           "-s ", "emulator-5566",
                                           "shell",
                                           "rm", "-f", emulatorBinPath,
                                           logger: logger)
        try await coomand.execute()
    }
    
    /// Copy file to emulator. File will be copyed to destination folder and might be renamed if needed. Destination folder doesn't have any structure
    /// - Parameters:
    ///   - source: file url
    ///   - filename: name of destination file, pass nil, if we need to keep the same name
    func copy(_ source: URL, filename: String? = nil) async throws {

        let resFilename = filename ?? source.lastPathComponent

        let coomand = ExecuteBinaryCommand(adbBinaryUrl,
                                           "-s ", "emulator-5566",
                                           "push", source.path(), emulatorBinPath + resFilename,
                                           logger: logger)
        try await coomand.execute()
    }

    func run(_ binaryName: String) async throws -> String {
        let coomand = ExecuteBinaryCommand(adbBinaryUrl,
                                           "-s ", "emulator-5566",
                                           "shell", "LD_LIBRARY_PATH=\(emulatorBinPath)",
                                           "/data/bin/\(binaryName)",
                                           logger: logger)
        return try await coomand.execute()
    }

    // MARK: Private

    private let androidSdk: AndroidSDK
    private let logger: Logger

    private let adbBinaryUrl: URL

    private let emulatorBinPath: String = "/data/bin/"
}
