import Foundation
import Logging

final class ArchedLibToolchainComponent: ToolchaninComponent {

    init(buildItem: BuildItemForAndroidArch) {
        self.buildItem = buildItem
    }

    // MARK: ToolchaninComponent

    func copy(to url: URL, config: BuildConfig, logger: Logging.Logger) async throws {

        logger.info("Copying libs only from \(buildItem.name)")

        let destinationFolder = config.toolchainAndroidsLib(for: buildItem.arch)

        let installFolder = config.installLocation(for: buildItem)
        let libsFolder = installFolder.appending(path: "lib/")
        let allFilesInLib = try fileManager.categorizedFolderContent(at: libsFolder).files

        // We have icu libs, which has symlinks, and I copy with them, because SONAME in lib actually *.so.65, not event .so.65.1
        // So I will copy symlinks too
        // If there will be an issue, we can patch elf files - here is answer from [stackoverflow](https://stackoverflow.com/questions/18467163/is-there-any-way-to-change-the-soname-of-a-binary-directly)
        // We need patch SOANEM and some libs in NEEDED
        let libsSoFiles = allFilesInLib.filter { fileUrl in
            fileUrl.pathExtension == "so" || fileUrl.lastPathComponent.contains(".so.")
        }

        for libsSoFile in libsSoFiles {
            let destination = destinationFolder.appending(path: libsSoFile.lastPathComponent)
            try fileManager.copyItem(at: libsSoFile, to: destination)
        }
    }

    // MARK: Private

    private let buildItem: BuildItemForAndroidArch
    private var fileManager: FileManager { .default }
}
