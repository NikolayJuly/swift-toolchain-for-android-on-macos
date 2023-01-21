import Foundation

enum Repos {
    static let checkoutOrder: [Checkoutable] = [
        swift,
        llvm,
        cmark,
        yams,
        swiftArgumentParser,
        swiftSystem,
        llbuild,
        swiftDriver,
        crypto,
        collections,
        spm,
    ]

    static let buildOrder: [ConfigurableRepo & BuildableRepo] = [
        LlvmProjectRepo(),
    ]

    static let swift = SwiftRepo()
    static let llvm = LlvmProjectRepo()
    static let cmark = CMarkRepo()
    static let yams = YamsRepo()
    static let swiftArgumentParser = SwiftArgumentParserRepo()
    static let swiftSystem = SwiftSystemRepo()
    static let llbuild = SwiftLLBuildCoreRepo()
    static let swiftDriver = SwiftDriverRepo()
    static let crypto = SwiftCryptoRepo()
    static let collections = SwiftCollectionsRepo()
    static let spm = SPMRepo()
}

struct SwiftRepo: ConfigurableRepo {
    let githubUrl = "https://github.com/apple/swift.git"

    let revision: CheckoutRevision = .tag("swift-5.7-RELEASE")

    let cmakeCacheEntries: [String] = []
}

struct LlvmProjectRepo: ConfigurableRepo, BuildableRepo {
    let githubUrl = "https://github.com/apple/llvm-project.git"

    let buildSubfolder: String? = "llvm"

    let cmakeCacheEntries: [String] = [
        "LLVM_INCLUDE_EXAMPLES=false",
        "LLVM_INCLUDE_TESTS=false",
        "LLVM_INCLUDE_DOCS=false",
        "LLVM_BUILD_TOOLS=false",
        "LLVM_INSTALL_BINUTILS_SYMLINKS=false",
        "LLVM_ENABLE_ASSERTIONS=TRUE",
        "LLVM_BUILD_EXTERNAL_COMPILER_RT=TRUE",
        "LLVM_ENABLE_PROJECTS=clang",
    ]

    let targets: [String] = [
        "clang",
        "llvm-tblgen",
        "clang-tblgen",
        "llvm-libraries",
        "clang-libraries"
    ]
}

struct CMarkRepo: ConfigurableRepo {
    let githubUrl = "https://github.com/apple/swift-cmark.git"

    let cmakeCacheEntries: [String] = []
}

struct YamsRepo: ConfigurableRepo {
    let githubUrl = "https://github.com/jpsim/yams.git"

    let cmakeCacheEntries: [String] = []
}

struct SwiftArgumentParserRepo: ConfigurableRepo {
    let githubUrl = "https://github.com/apple/swift-argument-parser.git"

    let cmakeCacheEntries: [String] = []
}

struct SwiftSystemRepo: ConfigurableRepo {
    let githubUrl = "https://github.com/apple/swift-system.git"

    let cmakeCacheEntries: [String] = []
}

struct SwiftLLBuildCoreRepo: ConfigurableRepo {
    let githubUrl = "https://github.com/apple/swift-llbuild.git"

    let cmakeCacheEntries: [String] = []
}

struct SwiftDriverRepo: ConfigurableRepo {
    let githubUrl = "https://github.com/apple/swift-driver.git"

    let cmakeCacheEntries: [String] = []
}

struct SwiftCryptoRepo: ConfigurableRepo {
    let githubUrl = "https://github.com/apple/swift-crypto.git"

    let cmakeCacheEntries: [String] = []
}

struct SwiftCollectionsRepo: ConfigurableRepo {
    let githubUrl = "https://github.com/apple/swift-collections.git"

    let cmakeCacheEntries: [String] = []
}

struct SPMRepo: ConfigurableRepo {
    let repoName: String = "swiftpm"

    let githubUrl = "https://github.com/apple/swift-package-manager.git"

    let cmakeCacheEntries: [String] = []
}


