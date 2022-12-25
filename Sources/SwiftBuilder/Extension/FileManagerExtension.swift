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
}
