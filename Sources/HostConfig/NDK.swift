import Foundation
import FoundationExtension

public struct NDK {

    /// For now support one major version per toolchain. Assumption here, that structure not gonna change in minor of patch releases
    public static let version: String = "25"

    // TODO: Consider getting this versions from NDK itself on init, rather than hardcoding them
    /// Compilers version in specific NDK version
    public static let gccVersion: String = "4.9"
    public static let clangVersion: String = "14.0.6"

    public let folderUrl: URL

    public let toolchain: URL

    public init(folderPath: String) throws {
        let url = URL(filePath: folderPath, directoryHint: .isDirectory)
        try self.init(folderUrl: url)
    }

    /// On init, NDK will execute minor validation, to make sure that it has expected structure and version
    public init(folderUrl: URL) throws {

        let fileManager = FileManager.default
        let ndkVersionString = folderUrl.lastPathComponent
        let version = try Version(ndkVersionString)

        guard "\(version.major)" == Self.version else {
            throw SimpleError("Currently we workign only with NDK v\(version)")
        }

        self.toolchain = folderUrl.appending(path: "/toolchains/llvm/prebuilt/darwin-x86_64", directoryHint: .isDirectory)

        guard fileManager.folderExists(at: toolchain) else {
            throw SimpleError("Failed to find toolchain folder at \(toolchain.path())")
        }

        self.folderUrl = folderUrl
    }
}
