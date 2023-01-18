import Foundation

enum Repos {
    static let allRepos: [Checkoutable] = [
        SwiftRepo(),
        LlvmProjectRepo(),
        CMarkRepo(),
        YamsRepo(),
        SwiftArgumentParserRepo(),
        SwiftSystemRepo(),
        SwiftLLBuildCoreRepo(),
        SwiftDriverRepo(),
        SwiftCryptoRepo(),
        SwiftCollectionsRepo(),
        SPMRepo()
    ]
}

struct SwiftRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift.git"

    let revision: CheckoutRevision = .tag("swift-5.7-RELEASE")
}

struct LlvmProjectRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/llvm-project.git"
}

struct CMarkRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift-cmark.git"
}

struct YamsRepo: Checkoutable {
    let githubUrl = "https://github.com/jpsim/yams.git"
}

struct SwiftArgumentParserRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift-argument-parser.git"
}

struct SwiftSystemRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift-system.git"
}

struct SwiftLLBuildCoreRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift-llbuild.git"
}

struct SwiftDriverRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift-driver.git"
}

struct SwiftCryptoRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift-crypto.git"
}

struct SwiftCollectionsRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift-collections.git"
}

struct SPMRepo: Checkoutable {
    let githubUrl = "https://github.com/apple/swift-package-manager.git"

    let repoName: String = "swiftpm"
}


