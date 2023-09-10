import Foundation
import FoundationExtension

public struct AndroidSDK {

    public let sdkRootUrl: URL

    public let ndk: NDK
    public let cmake: CMake

    /// On init, AndroidSDK will search for valid cmake and ndk
    public init(path: String) throws {

        self.sdkRootUrl = URL(filePath: path, directoryHint: .isDirectory)

        let fileManager = FileManager.default

        guard fileManager.folderExists(at: sdkRootUrl) else {
            throw SimpleError("Android SDK folder doesn't exist at \(path)")
        }

        let ndksFolderPath = path + "/ndk"

        self.ndk = try Self.create(itemsFolderPath: ndksFolderPath, name: "ndk", create: NDK.init)

        let cmakesFolderPath = path + "/cmake"

        self.cmake = try Self.create(itemsFolderPath: cmakesFolderPath, name: "cmake", create: CMake.init)
    }

    private static func create<T>(itemsFolderPath: String, name: String, create: @escaping (URL) throws -> T) throws -> T {
        let itemsUrl = URL(filePath: itemsFolderPath, directoryHint: .isDirectory)

        let fileManager = FileManager.default

        guard fileManager.folderExists(at: itemsUrl) else {
            throw SimpleError("Failed to find \(name) folder at \(itemsUrl.path())")
        }

        let (_, fodlers) = try fileManager.categorizedFolderContent(at: itemsUrl)

        guard fodlers.isEmpty == false else {
            throw SimpleError("Failed to find any \(name) folder in \(fodlers)")
        }

        var errors = [Error]()

        let item = fodlers.lazy.compactMap { folderUrl in
            do {
                return try create(folderUrl)
            } catch {
                errors.append(error)
                return nil
            }
        }.first

        guard let item else {
            throw CompositeError(errors)
        }

        return item
    }
}
