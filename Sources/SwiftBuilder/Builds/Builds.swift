import AndroidConfig
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

        let customExecutables: [BuildableItem] = [
            SwiftcAndroidBuild()
        ]

        return upToSwift + icus +  libs + customExecutables
    }()

    static let llvm = LlvmProjectBuild()

    static let toolsSupportCore = SwiftToolsSupportCoreBuild(dependencies: [
        "SwiftSystem": Repos.swiftSystem
    ])

    static let llbuild = SwiftLLBuildBuild()
    
    static let spm = SPMBuild(dependencies: [
        "TSC": Builds.toolsSupportCore,
        "LLBuild": Builds.llbuild,
        "ArgumentParser": Repos.swiftArgumentParser,
        "SwiftSystem": Repos.swiftSystem,
        "SwiftDriver": Repos.swiftDriver,
        "SwiftCrypto": Repos.crypto,
        "SwiftCollections": Repos.collections,
    ])
    
    static let swift = SwiftBuild(dependencies: [
        "LLVM": LLVMModule(),
        "Clang": LLVMModule(),
        "Cmark": CmarkAsDependency(),
        "NDK": NDKDependency(),
    ])

    static let icus: [BuildableItem] = {
        return [hostIcu] + androidIcus
    }()

    static let hostIcu = ICUHostBuild()

    static let androidIcus: [ICUBuild] = {
        AndroidArchs.all.map { ICUBuild(arch: $0) }
    }()

    static let libs: [BuildableItem] = {
        let libs: [BuildableItem] = AndroidArchs.all.flatMap { arch -> [BuildableItem] in
            let stdLib = StdLibBuild(
                arch: arch,
                dependencies: [
                    "LLVM": LLVMModule(),
                    "LibDispatch": Repos.libDispatchRepo,
                    "NDK": NDKDependency(),
                ]
            )

            let icu = androidIcus.first { $0.arch == arch }!

            let libXml = LibXml2Build(arch: arch)

            let openSSL = LibOpenSSLBuild(arch: arch)

            let curl = LibCurlBuild(arch: arch, openSSL: openSSL)

            let libDispatch = LibDispatchBuild(arch: arch,
                                               stdlib: stdLib)

            let libFoundation = LibFoundationBuild(arch: arch,
                                                   dispatch: libDispatch,
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
    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String] {
        let depBuildUrl = config.buildLocation(for: llvm)
        let res = depName + "_DIR=\"\(depBuildUrl.path)/lib/cmake/\(depName.lowercased())\""
        return [res]
    }

    private var llvm: BuildableItem { Builds.llvm }
}

struct CmarkAsDependency: BuildableItemDependency {
    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String] {
        let depRepoUrl = config.location(for: cmark)
        let depBuildUrl = config.buildLocation(for: cmark)
        return [
            "SWIFT_PATH_TO_CMARK_SOURCE=\"\(depRepoUrl.path)\"",
            "SWIFT_PATH_TO_CMARK_BUILD=\"\(depBuildUrl.path)\""
        ]
    }

    private var cmark: Checkoutable & BuildableItem { Repos.cmark }
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
