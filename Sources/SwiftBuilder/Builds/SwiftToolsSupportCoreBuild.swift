import Foundation

struct SwiftToolsSupportCoreBuild: BuildableItemDependency, NinjaBuildableItem {
    var name: String { tscRepo.repoName }

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.location(for: tscRepo)
    }

    let dependencies: [String: BuildableItemDependency]

    init(dependencies: [String: BuildableItemDependency],
         tscRepo: SwiftToolsSupportCoreRepo) {
        self.dependencies = dependencies
        self.tscRepo = tscRepo
    }

    // MARK: Private

    private let tscRepo: SwiftToolsSupportCoreRepo
}
