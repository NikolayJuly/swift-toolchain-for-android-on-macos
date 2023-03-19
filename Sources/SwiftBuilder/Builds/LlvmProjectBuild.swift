import Foundation

struct LlvmProjectBuild: BuildRepoItem, NinjaBuildableItem {

    // MARK: BuildRepoItem

    var repo: Checkoutable { Repos.llvm }

    // MARK: BuildableItem

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        let repoUrl = buildConfig.location(for: repo)
        return repoUrl.appendingPathComponent("llvm", isDirectory: true)
    }

    // MARK: NinjaBuildableItem

    let targets: [String] = [
        "clang",
        "llvm-tblgen",
        "clang-tblgen",
        "llvm-libraries",
        "clang-libraries"
    ]

    func cmakeCacheEntries(config: BuildConfig) -> [String] {
        [
            "LLVM_INCLUDE_EXAMPLES=false",
            "LLVM_INCLUDE_TESTS=false",
            "LLVM_INCLUDE_DOCS=false",
            "LLVM_BUILD_TOOLS=false",
            "LLVM_INSTALL_BINUTILS_SYMLINKS=false",
            "LLVM_ENABLE_ASSERTIONS=TRUE",
            "LLVM_BUILD_EXTERNAL_COMPILER_RT=TRUE",
            "LLVM_ENABLE_PROJECTS=clang",
        ]
    }
}
