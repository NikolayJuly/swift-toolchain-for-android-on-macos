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
        libDispatchRepo,
        foundationRepo,
        icu,
        libXML2,
        openSSL,
        curl,
    ]

    static let llvm = LlvmProjectRepo()
    static let cmark = CMarkRepo()
    static let yams = YamsRepo()
    static let swiftArgumentParser = SwiftArgumentParserRepo()
    static let swiftSystem = SwiftSystemRepo()
    static let llbuild = SwiftLLBuildRepo()
    static let crypto = SwiftCryptoRepo()
    static let collections = SwiftCollectionsRepo()
    static let toolsSupportCore = SwiftToolsSupportCoreRepo()

    static let swiftDriver = SwiftDriverRepo(dependencies: [
        "TSC": Builds.toolsSupportCore,
        "LLBuild": Builds.llbuild,
        "Yams": yams,
        "ArgumentParser": swiftArgumentParser,
        "SwiftSystem": swiftSystem,
    ])

    static let spm = SPMRepo()

    static let swift = SwiftRepo()

    static let libDispatchRepo = LibDispatchRepo()
    static let icu = ICURepo()
    static let libXML2 = LibXml2Repo()
    static let openSSL = OpenSSLRepo()
    static let curl = CurlRepo()
    static let foundationRepo = FoundationRepo()
}

struct LlvmProjectRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/llvm-project.git"

    func licencies(config: BuildConfig) throws -> [String] {
        [
            "LICENSE.txt",
            "clang/LICENSE.txt",
            "compiler-rt/LICENSE.txt"
        ]
    }
}

struct CMarkRepo: BuildableItem, Checkoutable, NinjaBuildableItem {
    let githubUrl = "https://github.com/apple/swift-cmark.git"

    let repoName: String = "cmark"

    func cmakeCacheEntries(config: BuildConfig) -> [String] {
        [
            "CMARK_TESTS=false",
            "CMAKE_C_FLAGS=\"-Wno-unknown-warning-option -Werror=unguarded-availability-new -fno-stack-protector\"",
            "CMAKE_CXX_FLAGS=\"-Wno-unknown-warning-option -Werror=unguarded-availability-new -fno-stack-protector\"",
        ]
    }
}

struct YamsRepo: BuildableItem, BuildableItemDependency, Checkoutable, NinjaBuildableItem {
    let githubUrl = "https://github.com/jpsim/yams.git"
}

struct SwiftArgumentParserRepo: BuildableItem, BuildableItemDependency, Checkoutable, NinjaBuildableItem {

    let githubUrl = "https://github.com/apple/swift-argument-parser.git"

    func cmakeCacheEntries(config: BuildConfig) -> [String] {
        [
            "BUILD_SHARED_LIBS=YES",
            "BUILD_EXAMPLES=FALSE",
            "BUILD_TESTING=FALSE",
        ]
    }
}

struct SwiftSystemRepo: BuildableItem, BuildableItemDependency, Checkoutable, NinjaBuildableItem {
    let githubUrl = "https://github.com/apple/swift-system.git"
}

struct SwiftToolsSupportCoreRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift-tools-support-core.git"
}

struct SwiftLLBuildRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift-llbuild.git"    
}

struct SwiftDriverRepo: BuildableItem, BuildableItemDependency, Checkoutable, NinjaBuildableItem {
    let githubUrl = "https://github.com/apple/swift-driver.git"

    let dependencies: [String: BuildableItemDependency]

    init(dependencies: [String: BuildableItemDependency]) {
        self.dependencies = dependencies
    }
}

struct SwiftCryptoRepo: BuildableItem, BuildableItemDependency, Checkoutable, NinjaBuildableItem {
    let githubUrl = "https://github.com/apple/swift-crypto.git"
}

struct SwiftCollectionsRepo: BuildableItem, BuildableItemDependency, Checkoutable, NinjaBuildableItem {
    let githubUrl = "https://github.com/apple/swift-collections.git"
}

struct SPMRepo: Checkoutable {
    let repoName: String = "swiftpm"

    let githubUrl = "https://github.com/apple/swift-package-manager.git"    
}

struct SwiftRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift.git"

    let revision: CheckoutRevision = .tag("swift-5.7-RELEASE")
}

struct LibDispatchRepo: BuildableItemDependency, Checkoutable {
    let githubUrl = "https://github.com/apple/swift-corelibs-libdispatch.git"

    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String] {
        return [
            "SWIFT_PATH_TO_LIBDISPATCH_SOURCE=\"\(config.location(for: self).path)\"",
        ]
    }
}

struct ICURepo: Checkoutable {
    let githubUrl = "https://github.com/unicode-org/icu.git"

    func licencies(config: BuildConfig) throws -> [String] {
        [
            "icu4c/LICENSE"
        ]
    }
}

struct LibXml2Repo: Checkoutable {
    let githubUrl = "https://github.com/GNOME/libxml2"

    let revision: CheckoutRevision = .tag("v2.10.3")
}

struct CurlRepo: Checkoutable {
    let githubUrl = "https://github.com/curl/curl"

    let revision: CheckoutRevision = .tag("curl-7_88_1")
}

struct OpenSSLRepo: Checkoutable {
    let githubUrl = "https://github.com/openssl/openssl"

    let revision: CheckoutRevision = .tag("openssl-3.1.0")
}

struct FoundationRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift-corelibs-foundation"
}



