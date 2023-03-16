import Foundation

struct LlvmProjectBuild: NinjaBuildableItem {
    init(repo: LlvmProjectRepo) {
        self.repo = repo
    }

    // MARK: BuildableItem
    var name: String { repo.repoName }

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.location(for: repo)
    }

    // MARK: NinjaBuildableItem

    let buildSubfolder: String? = "llvm"

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

    private let repo: LlvmProjectRepo
}
