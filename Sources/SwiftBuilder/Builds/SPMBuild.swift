import Foundation

struct SPMBuild: NinjaBuildableItem {

    init(repo: SPMRepo,
         dependencies: [String: BuildableItemDependency]) {
        self.repo = repo
        self.dependencies = dependencies
    }

    // MARK: NinjaBuildableItem

    var name: String { repo.repoName }

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.location(for: repo)
    }

    let dependencies: [String: BuildableItemDependency]

    func cmakeCacheEntries(config: BuildConfig) -> [String] {
        [
            "CMAKE_Swift_FLAGS=\"-Xlinker -rpath -Xlinker @executable_path/../lib\"",
            "USE_CMAKE_INSTALL=TRUE",
            "CMAKE_BUILD_WITH_INSTALL_RPATH=true",
        ]
    }

    // MARK: Private

    private let repo: SPMRepo
}
