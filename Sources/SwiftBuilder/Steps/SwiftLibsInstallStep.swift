import Foundation
import Logging

/// Some install operation require minor fixing after it, so we can easy copy files to toolchain
final class SwiftLibsInstallStep: BuildStep {

    var stepName: String { "install-\(buildItem.name)" }

    init(buildItem: BuildItemForAndroidArch) {
        self.buildItem = buildItem
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {
        let defautlInstall = CmakeInstallStep(buildableItem: buildItem)
        try await defautlInstall.execute(config, logger: logger)

        // We need move to some files:
        // - for comfort, we need remove top level `usr` folder, it will allow us simpler copying to toolchain later
        // - we need move .so files to `lib/swift/android/<arch>` from just `lib/swift/android`, to simplify copying later
        let installFodler = config.installLocation(for: buildItem)
        let usrUrl = installFodler.appending(path: "usr/")
        if fileManager.folderExists(at: usrUrl) {
            let libUrl = usrUrl.appending(path: "lib/")
            let libDestination = installFodler.appending(path: "lib/")
            try? fileManager.removeItem(at: libDestination)
            try fileManager.moveItem(at: libUrl, to: libDestination)
            try fileManager.removeItem(at: usrUrl)
        }

        let adroidFolder = installFodler.appending(path: "lib/swift/android/")
        let soFiles = try fileManager.categorizedFolderContent(at: adroidFolder).files.filter { $0.pathExtension == "so" }
        let archFolder = adroidFolder.appending(path: buildItem.arch.swiftArch + "/")
        for file in soFiles {
            let destination = archFolder.appending(path: file.lastPathComponent)
            try? fileManager.removeItem(at: destination)
            try fileManager.moveItem(at: file, to: destination)
        }
    }

    // MARK: Private

    private let buildItem: BuildItemForAndroidArch
    private var fileManager: FileManager { .default }
}
