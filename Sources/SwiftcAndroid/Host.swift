import Foundation
import FoundationExtension
import HostConfig

struct Host {

    let ndk: NDK

    init() throws {
        let ndkDefaultPath = "Library/Android/sdk/ndk"

        let envNdkPath = ProcessInfo.processInfo.environment[.ndkPathEnvKey]
        let defaultNdksFolderUrl = fileManager.homeDirectoryForCurrentUser.appending(path: ndkDefaultPath, directoryHint: .isDirectory)

        var errors = [Error]()

        let defaultNDKFolder: URL?
        do {
            let (_, ndkFodlers) = try fileManager.categorizedFolderContent(at: defaultNdksFolderUrl)
            defaultNDKFolder = ndkFodlers.first
        } catch {
            defaultNDKFolder = nil
            errors.append(error)
        }

        let defaultNDKFolderPath = defaultNDKFolder?.path(percentEncoded: false)

        let paths: [String?] = [envNdkPath, defaultNDKFolderPath]
        let ndk: NDK? = paths.compactMap { $0 }.lazy
            .compactMap { path -> NDK? in
                do {
                    return try NDK(folderPath: path)
                } catch {
                    errors.append(error)
                    return nil
                }
            }.first

        guard let ndk else {
            throw CompositeError(errors, message: "Failed to find NDK. We check anv NDK_PATH and default path ~/\(ndkDefaultPath): \(paths.compactMap { $0 })")
        }

        self.ndk = ndk
    }
}
