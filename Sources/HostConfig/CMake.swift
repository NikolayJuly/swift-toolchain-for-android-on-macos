import Foundation
import FoundationExtension

public struct CMake {

    public let folderUrl: URL

    public let binFolder: URL

    public init(folderUrl: URL) throws {

        let fileManager = FileManager.default

        self.binFolder = folderUrl.appending(path: "bin", directoryHint: .isDirectory)
        guard fileManager.folderExists(at: binFolder) else {
            throw SimpleError("Failed to find bin fodler in cmake - \(binFolder.path())")
        }

        self.folderUrl = folderUrl
    }
}
