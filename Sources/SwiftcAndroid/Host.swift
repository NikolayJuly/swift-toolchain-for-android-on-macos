import Foundation
import FoundationExtension
import HostConfig

struct Host {

    let ndk: NDK

    init() throws {
        let ndkDefaultPath = "Library/Android/sdk/ndk"

        let envNdkPath = ProcessInfo.processInfo.environment[.ndkPathEnvKey]
        let envNdkUrl = envNdkPath.map { URL(filePath: $0, directoryHint: .isDirectory) }
        let defaultNdksFolderUrl = fileManager.homeDirectoryForCurrentUser.appending(path: ndkDefaultPath, directoryHint: .isDirectory)

        var errors = [Error]()

        let defaultNDKFolders: [URL]
        do {
            let (_, ndkFodlers) = try fileManager.categorizedFolderContent(at: defaultNdksFolderUrl)
            defaultNDKFolders = ndkFodlers
        } catch {
            defaultNDKFolders = []
            errors.append(error)
        }


        let folderUrls: [URL?] = [envNdkUrl] + defaultNDKFolders
        let ndk: NDK? = folderUrls.compactMap { $0 }.lazy
            .compactMap { folderUrl -> NDK? in
                do {
                    return try NDK(folderUrl: folderUrl)
                } catch {
                    errors.append(error)
                    return nil
                }
            }.first

        guard let ndk else {
            throw CompositeError(errors, message: "Failed to find NDK. We check anv NDK_PATH and default path ~/\(ndkDefaultPath): \(defaultNDKFolders.compactMap { $0 })")
        }

        self.ndk = ndk
    }
}
