import Foundation

enum Repos {
    static let checkoutOrder: [Checkoutable] = [
        swift,
        llvm,
        cmark,
        yams,
        swiftArgumentParser,
        swiftSystem,
        toolsSupportCore,
        llbuild,
        swiftDriver,
        crypto,
        collections,
        spm,
    ]

    static let buildOrder: [ConfigurableRepo & BuildableRepo] = [
        llvm,
        cmark,
        yams,
        swiftArgumentParser,
        swiftSystem,
        toolsSupportCore,
        llbuild,
        swiftDriver,
        crypto,
        collections,
        spm,
    ]

    static let swift = SwiftRepo()
    static let llvm = LlvmProjectRepo()
    static let cmark = CMarkRepo()
    static let yams = YamsRepo()
    static let swiftArgumentParser = SwiftArgumentParserRepo()
    static let swiftSystem = SwiftSystemRepo()
    static let toolsSupportCore = SwiftToolsSupportCoreRepo(dependencies: [
        "SwiftSystem": swiftSystem
    ])
    static let llbuild = SwiftLLBuildRepo()
    static let swiftDriver = SwiftDriverRepo(dependencies: [
        "TSC": toolsSupportCore,
        "LLBuild": llbuild,
        "Yams": yams,
        "ArgumentParser": swiftArgumentParser,
        "SwiftSystem": swiftSystem,
    ])
    static let crypto = SwiftCryptoRepo()
    static let collections = SwiftCollectionsRepo()
    static let spm = SPMRepo(dependencies: [
        "TSC": toolsSupportCore,
        "LLBuild": llbuild,
        "ArgumentParser": swiftArgumentParser,
        "SwiftSystem": swiftSystem,
        "SwiftDriver": swiftDriver,
        "SwiftCrypto": crypto,
        "SwiftCollections": collections,
    ])
}

struct SwiftRepo: ConfigurableRepo {
    let githubUrl = "https://github.com/apple/swift.git"

    let revision: CheckoutRevision = .tag("swift-5.7-RELEASE")
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

struct CMarkRepo: ConfigurableRepo, BuildableRepo {
    let githubUrl = "https://github.com/apple/swift-cmark.git"

    let cmakeCacheEntries: [String] = [
        "CMARK_TESTS=false",
        "CMAKE_C_FLAGS=\"-Wno-unknown-warning-option -Werror=unguarded-availability-new -fno-stack-protector\"",
        "CMAKE_CXX_FLAGS=\"-Wno-unknown-warning-option -Werror=unguarded-availability-new -fno-stack-protector\"",
    ]
}

struct YamsRepo: ConfigurableRepo, BuildableRepo {
    let githubUrl = "https://github.com/jpsim/yams.git"
}

struct SwiftArgumentParserRepo: ConfigurableRepo, BuildableRepo {
    let githubUrl = "https://github.com/apple/swift-argument-parser.git"

    let cmakeCacheEntries: [String] = [
        "BUILD_SHARED_LIBS=YES",
        "BUILD_EXAMPLES=FALSE",
        "BUILD_TESTING=FALSE",
    ]
}

struct SwiftSystemRepo: ConfigurableRepo, BuildableRepo {
    let githubUrl = "https://github.com/apple/swift-system.git"
}

struct SwiftToolsSupportCoreRepo: ConfigurableRepo, BuildableRepo {
    let githubUrl = "https://github.com/apple/swift-tools-support-core.git"

    let cmakeCacheEntries: [String] = [
        "SwiftSystem_DIR=/Users/nikolaydzhulay/ws/SwiftAndroid_working/build/swift-system/cmake/modules"
    ]

    let dependencies: [String: BuildableRepo]

    init(dependencies: [String: BuildableRepo]) {
        self.dependencies = dependencies
    }
}

struct SwiftLLBuildRepo: ConfigurableRepo, BuildableRepo {
    let githubUrl = "https://github.com/apple/swift-llbuild.git"

    let cmakeCacheEntries: [String] = [
        "CMAKE_Swift_FLAGS=\"-Xlinker -v -Xfrontend -target -Xfrontend arm64-apple-macosx10.10 -target arm64-apple-macosx10.10 -v\"",
        "LLBUILD_SUPPORT_BINDINGS=Swift",
        "CMAKE_OSX_ARCHITECTURES=arm64",
        "BUILD_SHARED_LIBS=false",
    ]
}

struct SwiftDriverRepo: ConfigurableRepo, BuildableRepo {
    let githubUrl = "https://github.com/apple/swift-driver.git"

    let dependencies: [String: BuildableRepo]

    init(dependencies: [String: BuildableRepo]) {
        self.dependencies = dependencies
    }
}

struct SwiftCryptoRepo: ConfigurableRepo, BuildableRepo {
    let githubUrl = "https://github.com/apple/swift-crypto.git"
}

struct SwiftCollectionsRepo: ConfigurableRepo, BuildableRepo {
    let githubUrl = "https://github.com/apple/swift-collections.git"
}

struct SPMRepo: ConfigurableRepo, BuildableRepo {
    let repoName: String = "swiftpm"

    let githubUrl = "https://github.com/apple/swift-package-manager.git"

    let dependencies: [String: BuildableRepo]

    init(dependencies: [String: BuildableRepo]) {
        self.dependencies = dependencies
    }
}


