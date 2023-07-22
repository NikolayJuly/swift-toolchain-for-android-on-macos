import AndroidConfig
import Foundation

// TODO: Rename struct and property to show actual purpose - apply patches
struct BuildableItemRepo {
    let checkoutable: Checkoutable
    let patchFileName: String
}

protocol BuildableItem {
    // Will be used as folder or file name part, where needed
    var name: String { get }

    // TODO: Rename struct and property to show actual purpose - apply patches
    var underlyingRepo: BuildableItemRepo? { get }

    func sourceLocation(using buildConfig: BuildConfig) -> URL

    func buildSteps() -> [BuildStep]
}

protocol BuildRepoItem: BuildableItem {
    var repo: Checkoutable { get }
}

protocol BuildItemForAndroidArch: BuildRepoItem {
    var arch: AndroidArch { get }
}

extension BuildableItem {
    var underlyingRepo: BuildableItemRepo? { nil }
}

extension BuildableItem where Self: Checkoutable {
    var name: String { repoName }

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.location(for: self)
    }

    // TODO: Rename struct and property to show actual purpose - apply patches
    var underlyingRepo: BuildableItemRepo? {
        BuildableItemRepo(checkoutable: self,
                          patchFileName: repoName + ".patch")
    }
}

extension BuildableItem where Self: BuildRepoItem {
    var name: String { repo.repoName }

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.location(for: repo)
    }

    // TODO: Rename struct and property to show actual purpose - apply patches
    var underlyingRepo: BuildableItemRepo? {
        BuildableItemRepo(checkoutable: repo,
                          patchFileName: repo.repoName + ".patch")
    }
}

extension BuildableItem where Self: BuildItemForAndroidArch {
    var name: String { repo.repoName + "-" + arch.name }
}

extension BuildConfig {
    func buildLocation(for buildableItem: BuildableItem) -> URL {
        return buildsRootFolder.appendingPathComponent(buildableItem.name, isDirectory: true)
    }
}

extension BuildConfig {
    func installLocation(for buildableItem: BuildableItem) -> URL {
        return installRootFolder.appendingPathComponent(buildableItem.name, isDirectory: true)
    }
}
