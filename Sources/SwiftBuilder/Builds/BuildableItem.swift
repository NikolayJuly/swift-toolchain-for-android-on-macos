import Foundation

struct BuildableItemRepo {
    let checkoutable: Checkoutable
    let patchFileName: String
}

protocol BuildableItem {
    // Will be used as folder or file name part, where needed
    var name: String { get }

    var buildSubfolder: String? { get }

    var underlyingRepo: BuildableItemRepo? { get }

    func sourceLocation(using buildConfig: BuildConfig) -> URL

    func buildSteps() -> [BuildStep]
}

extension BuildableItem {
    var buildSubfolder: String? { nil }

    var patchFileName: String { name }

    var underlyingRepo: BuildableItemRepo? { nil }
}

extension BuildableItem where Self: Checkoutable {
    var name: String { repoName }

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        var resUrl = buildConfig.location(for: self)
        if let buildSubfolder = self.buildSubfolder {
            resUrl = resUrl.appendingPathComponent(buildSubfolder, isDirectory: true)
        }
        return resUrl
    }

    var underlyingRepo: BuildableItemRepo? {
        BuildableItemRepo(checkoutable: self,
                          patchFileName: repoName + ".patch")
    }
}

extension BuildConfig {
    func buildLocation(for repo: BuildableItem) -> URL {
        return buildsRootFolder.appendingPathComponent(repo.name, isDirectory: true)
    }
}

extension BuildConfig {
    func installLocation(for repo: BuildableItem) -> URL {
        return installRootFolder.appendingPathComponent(repo.name, isDirectory: true)
    }
}
