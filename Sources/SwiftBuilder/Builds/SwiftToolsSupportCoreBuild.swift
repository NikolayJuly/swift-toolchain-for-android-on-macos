import Foundation

struct SwiftToolsSupportCoreBuild: BuildableItemDependency, BuildRepoItem, NinjaBuildableItem {

    var repo: Checkoutable { Repos.toolsSupportCore }

    let dependencies: [String: BuildableItemDependency]

    init(dependencies: [String: BuildableItemDependency]) {
        self.dependencies = dependencies
    }
}
