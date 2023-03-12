import Foundation

enum Builds {
    static let buildOrder: [BuildableItem] = {
        let upToSwift: [BuildableItem] = [
            Repos.llvm,
            Repos.cmark,
            Repos.yams,
            Repos.swiftArgumentParser,
            Repos.swiftSystem,
            Repos.toolsSupportCore,
            Repos.llbuild,
            Repos.swiftDriver,
            Repos.crypto,
            Repos.collections,
            Repos.spm,
            Repos.swift,
        ]

        return upToSwift + icus +  libs
    }()

    static let icus: [BuildableItem] = {
        let hostBuild = ICUHostBuild(repo: Repos.icu)
        let archBuilds = AndroidArchs.all.map { ICUBuild(arch: $0, repo: Repos.icu, hostBuild: hostBuild) }
        return [hostBuild] + archBuilds
    }()

    static let libs: [BuildableItem] = {
        let libs: [BuildableItem] = AndroidArchs.all.flatMap { arch -> [BuildableItem] in
            let stdLib = StdLibBuild(
                swift: Repos.swift,
                arch: arch,
                dependencies: [
                    "LLVM": LLVMModule(llvm: Repos.llvm),
                    "LibDispatch": Repos.libDispatchRepo,
                    "NDK": NDKDependency(),
                ]
            )

            let libDispatch = LibDispatchBuild(arch: arch,
                                               libDispatchRepo: Repos.libDispatchRepo,
                                               swift: Repos.swift,
                                               stdlib: stdLib)
            let libFoundation = LibFoundationBuild(arch: arch,
                                                   foundationRepo: Repos.foundationRepo,
                                                   dispatch: libDispatch,
                                                   swift: Repos.swift,
                                                   stdlib: stdLib)
            return [stdLib, libDispatch, libFoundation]
        }

        return libs
    }()

}

struct LLVMModule: BuildableItemDependency {
    init(llvm: LlvmProjectRepo) {
        self.llvm = llvm
    }

    func cmakeDepDirCaheEntry(depName: String, config: BuildConfig) -> [String] {
        let depBuildUrl = config.buildLocation(for: llvm)
        let res = depName + "_DIR=\"\(depBuildUrl.path)/lib/cmake/\(depName.lowercased())\""
        return [res]
    }

    private let llvm: LlvmProjectRepo
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
