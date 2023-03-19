import Foundation

enum Builds {
    static let buildOrder: [BuildableItem] = {
        let upToSwift: [BuildableItem] = [
            Builds.llvm,
            Repos.cmark,
            Repos.yams,
            Repos.swiftArgumentParser,
            Repos.swiftSystem,
            Builds.toolsSupportCore,
            Builds.llbuild,
            Repos.swiftDriver,
            Repos.crypto,
            Repos.collections,
            Builds.spm,
            Builds.swift,
        ]

        return upToSwift + icus +  libs
    }()

    static let llvm = LlvmProjectBuild(repo: Repos.llvm)

    static let toolsSupportCore = SwiftToolsSupportCoreBuild(
        dependencies: [
            "SwiftSystem": Repos.swiftSystem
        ],
        tscRepo: Repos.toolsSupportCore
    )

    static let llbuild = SwiftLLBuildBuild(repo: Repos.llbuild)

    static let spm = SPMBuild(
        repo: Repos.spm,
        dependencies: [
            "TSC": Builds.toolsSupportCore,
            "LLBuild": Builds.llbuild,
            "ArgumentParser": Repos.swiftArgumentParser,
            "SwiftSystem": Repos.swiftSystem,
            "SwiftDriver": Repos.swiftDriver,
            "SwiftCrypto": Repos.crypto,
            "SwiftCollections": Repos.collections,
        ]
    )

    static let swift = SwiftBuild(
        repo: Repos.swift,
        dependencies: [
            "LLVM": LLVMModule(llvm: Builds.llvm),
            "Clang": LLVMModule(llvm: Builds.llvm),
            "Cmark": CmarkAsDependency(cmark: Repos.cmark),
            "NDK": NDKDependency(),
        ]
    )

    static let icus: [BuildableItem] = {
        return [hostIcu] + androidIcus
    }()

    static let hostIcu = ICUHostBuild(repo: Repos.icu)

    static let androidIcus: [ICUBuild] = {
        AndroidArchs.all.map { ICUBuild(arch: $0, repo: Repos.icu, hostBuild: hostIcu) }
    }()

    static let libs: [BuildableItem] = {
        let libs: [BuildableItem] = AndroidArchs.all.flatMap { arch -> [BuildableItem] in
            let stdLib = StdLibBuild(
                swift: Builds.swift,
                arch: arch,
                dependencies: [
                    "LLVM": LLVMModule(llvm: Builds.llvm),
                    "LibDispatch": Repos.libDispatchRepo,
                    "NDK": NDKDependency(),
                ]
            )

            let icu = androidIcus.first { $0.arch == arch }!

            let libXml = LibXml2Build(repo: Repos.libXML2, arch: arch)

            let openSSL = LibOpenSSLBuild(repo: Repos.openSSL, arch: arch)

            let curl = LibCurlBuild(repo: Repos.curl, arch: arch, openSSL: openSSL)

            let libDispatch = LibDispatchBuild(arch: arch,
                                               libDispatchRepo: Repos.libDispatchRepo,
                                               swift: Builds.swift,
                                               stdlib: stdLib)
            let libFoundation = LibFoundationBuild(arch: arch,
                                                   foundationRepo: Repos.foundationRepo,
                                                   dispatch: libDispatch,
                                                   swift: Builds.swift,
                                                   stdlib: stdLib,
                                                   icu: icu,
                                                   curl: curl,
                                                   libXml2: libXml)
            return [stdLib, libDispatch, libXml, openSSL, curl, libFoundation]
        }

        return libs
    }()

}

struct LLVMModule: BuildableItemDependency {
    init(llvm: LlvmProjectBuild) {
        self.llvm = llvm
    }

    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String] {
        let depBuildUrl = config.buildLocation(for: llvm)
        let res = depName + "_DIR=\"\(depBuildUrl.path)/lib/cmake/\(depName.lowercased())\""
        return [res]
    }

    private let llvm: LlvmProjectBuild
}

struct CmarkAsDependency: BuildableItemDependency {
    init(cmark: CMarkRepo) {
        self.cmark = cmark
    }

    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String] {
        let depRepoUrl = config.location(for: cmark)
        let depBuildUrl = config.buildLocation(for: cmark)
        return [
            "SWIFT_PATH_TO_CMARK_SOURCE=\"\(depRepoUrl.path)\"",
            "SWIFT_PATH_TO_CMARK_BUILD=\"\(depBuildUrl.path)\""
        ]
    }

    private let cmark: CMarkRepo
}

struct NDKDependency: BuildableItemDependency {
    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String] {
        [
            "SWIFT_ANDROID_NDK_PATH=\"\(config.ndkPath)\"",
            "SWIFT_ANDROID_NDK_GCC_VERSION=" + config.ndkGccVersion,
            "SWIFT_ANDROID_API_LEVEL=" + config.androidApiLevel,
            "SWIFT_ANDROID_NDK_CLANG_VERSION=" + config.ndkClangVersion,
        ]
    }
}
