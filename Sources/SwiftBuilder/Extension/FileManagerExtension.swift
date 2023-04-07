import Foundation

extension FileManager {
    func fileExists(at fileUrl: URL) -> Bool {
        var isDir: ObjCBool = false
        let exists = fileExists(atPath: fileUrl.path, isDirectory: &isDir)

        return exists && !isDir.boolValue
    }

    func folderExists(at folderUrl: URL) -> Bool {
        var isDir: ObjCBool = false
        let folderExists = fileExists(atPath: folderUrl.path, isDirectory: &isDir)

        return folderExists && isDir.boolValue
    }

    func createEmptyFolder(at folderUrl: URL) throws {
        try? removeItem(at: folderUrl)
        try createDirectory(at: folderUrl, withIntermediateDirectories: false, attributes: nil)
    }

    func createFolderIfNotExists(at folderUrl: URL) throws {
        guard !folderExists(at: folderUrl) else {
            return
        }

        do {
            try createDirectory(at: folderUrl, withIntermediateDirectories: false, attributes: nil)
        } catch let exc {
            throw "Failed to create fodler at \(folderUrl.absoluteURL): \(exc)"
        }
    }

    public func categorizedFolderContent(at folderUrl: URL) throws -> (files: [URL], folders: [URL]) {
        let urls = try contentsOfDirectory(at: folderUrl, includingPropertiesForKeys: [.isDirectoryKey])

        var files = [URL]()
        var folders = [URL]()
        folders.reserveCapacity(urls.count)
        files.reserveCapacity(urls.count)

        for url in urls {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey])

            let isFolder: Bool
            if let isDirectory = values.isDirectory {
                isFolder = isDirectory
            } else {
                assert(false, "We request this resource value, when created urls, so info should exists")
                isFolder = folderExists(at: url)
            }
            if isFolder {
                folders.append(url)
            } else {
                files.append(url)
            }
        }
        return (files, folders)
    }
}
