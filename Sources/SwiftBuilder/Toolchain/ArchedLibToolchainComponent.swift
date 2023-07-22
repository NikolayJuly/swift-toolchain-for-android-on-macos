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
        let libsSoFiles = try fileManager.categorizedFolderContent(at: libsFolder).files.filter { $0.pathExtension == "so" }

        for libsSoFile in libsSoFiles {
            let destination = destinationFolder.appending(path: libsSoFile.lastPathComponent)
            try fileManager.copyItem(at: libsSoFile, to: destination)
        }
    }

    // MARK: Private

    private let buildItem: BuildItemForAndroidArch
    private var fileManager: FileManager { .default }
}
