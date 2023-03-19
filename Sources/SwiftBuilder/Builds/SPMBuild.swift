import Foundation

struct SPMBuild: BuildRepoItem, NinjaBuildableItem {

    var repo: Checkoutable { Repos.spm }

    init(dependencies: [String: BuildableItemDependency]) {
        self.dependencies = dependencies
    }

    // MARK: NinjaBuildableItem

    let dependencies: [String: BuildableItemDependency]

    func cmakeCacheEntries(config: BuildConfig) -> [String] {
        [
            "CMAKE_Swift_FLAGS=\"-Xlinker -rpath -Xlinker @executable_path/../lib\"",
            "USE_CMAKE_INSTALL=TRUE",
            "CMAKE_BUILD_WITH_INSTALL_RPATH=true",
        ]
    }
}
