import Foundation

struct SwiftLLBuildBuild: BuildableItemDependency, NinjaBuildableItem {
    init(repo: SwiftLLBuildRepo) {
        self.repo = repo
    }

    // MARK: NinjaBuildableItem

    var name: String { repo.repoName }

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.location(for: repo)
    }

    func cmakeCacheEntries(config: BuildConfig) -> [String] {
        // Here we have targer arch and macos version, and I might probably replace arm64 here with macOs arch, but 10.10 make no sense to replace with 12, as few placeses parse and looks like expect 10.x
        // TODO: Figure out does it work on x86_64, and find actual list of valid values. Will it accept arm64-apple-macosx13.0 ?!
        //       According to error from cmake, this mcosx13.0 is invalid value
        //             <unknown>:0: error: unable to load standard library for target 'arm64-apple-macosx13.0'
        //       Initial value was `arm64-apple-macosx10.10`
        //       I replaced arch and macOS version here, assuming that same values are valid with x86_64 arch.
        let target = "\(config.macOsArch)-apple-macosx\(config.macOsTarget)"

        return [
            "CMAKE_Swift_FLAGS=\"-Xlinker -v -Xfrontend -target -Xfrontend \(target) -target \(target) -v\"",
            "LLBUILD_SUPPORT_BINDINGS=Swift",
            "CMAKE_OSX_ARCHITECTURES=\(config.macOsArch)",
            "BUILD_SHARED_LIBS=false",
        ]
    }

    // MARK: Private

    private let repo: SwiftLLBuildRepo
}
