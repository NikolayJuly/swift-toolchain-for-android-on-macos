import Foundation

protocol BuildableItemDependency {
    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String]
}

extension BuildableItemDependency where Self: BuildableItem {
    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String] {
        let depBuildUrl = config.buildLocation(for: self)
        let res = depName + "_DIR=\"\(depBuildUrl.path)/cmake/modules\""
        return [res]
    }
}

protocol NinjaBuildableItem: BuildableItem {

    var targets: [String] { get }

    var buildSubfolder: String? { get }

    var dependencies: [String: BuildableItemDependency] { get }

    func cmakeCacheEntries(config: BuildConfig) -> [String]
}

extension NinjaBuildableItem {

    // Most of repos has 1 default target
    var targets: [String] { [] }

    var dependencies: [String: BuildableItemDependency] { [:] }

    func cmakeCacheEntries(config: BuildConfig) -> [String] { [] }

    func buildSteps() -> [BuildStep] {
        [
            ConfigureRepoStep(buildableItem: self),
            NinjaBuildStep(buildableRepo: self),
        ]
    }
}






