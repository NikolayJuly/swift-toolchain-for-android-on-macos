import Foundation
import Logging

public final class CMakeConfigure {
    public init(folderUrl: URL,
                cmakePath: String,
                buildFolder: URL,
                cacheEntries: [String],
                macOsTarget: String,
                logger: Logger) {
        self.folderUrl = folderUrl
        self.cmakePath = cmakePath
        self.buildFolder = buildFolder
        self.cacheEntries = cacheEntries
        self.macOsTarget = macOsTarget
        self.logger = logger
    }

    public func execute() async throws {
        let commandParths: [String] = [
            "cmake",
            "-G", "Ninja",
            "-S", folderUrl.path,
            "-B", buildFolder.path,
            "-D", "CMAKE_INSTALL_PREFIX=/",
            "-D", "CMAKE_OSX_DEPLOYMENT_TARGET=\(macOsTarget)",
            "-D", "CMAKE_BUILD_TYPE=Release"
        ] + cacheEntries.flatMap { ["-D", $0] }
        let command = ShellCommand(commandParths,
                                   environment: ["PATH": cmakePath],
                                   logger: logger)
        try await command.execute()
    }

    // MARK: Private

    private let folderUrl: URL
    private let cmakePath: String
    private let buildFolder: URL
    private let cacheEntries: [String]
    private let macOsTarget: String
    private let logger: Logger
}
