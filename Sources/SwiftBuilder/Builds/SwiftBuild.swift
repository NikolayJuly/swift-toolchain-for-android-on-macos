import AndroidConfig
import Foundation

struct SwiftBuild: BuildRepoItem, NinjaBuildableItem {

    var repo: Checkoutable { Repos.swift }

    init(dependencies: [String: BuildableItemDependency]) {
        self.dependencies = dependencies
    }

    // MARK: NinjaBuildableItem

    let dependencies: [String: BuildableItemDependency]

    func cmakeCacheEntries(config: BuildConfig) -> [String] {
        [
            "SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX=\(config.macOsTarget)",
            "SWIFT_HOST_VARIANT_ARCH=arm64",

            // SWIFT_ANDROID_NDK_PATH, SWIFT_ANDROID_NDK_GCC_VERSION, SWIFT_ANDROID_API_LEVEL - will be populated by `NDKDependency`

            "SWIFT_STDLIB_ENABLE_SIL_OWNERSHIP=FALSE",
            "SWIFT_ENABLE_GUARANTEED_NORMAL_ARGUMENTS=TRUE",
            "CMAKE_EXPORT_COMPILE_COMMANDS=TRUE",
            "SWIFT_STDLIB_ENABLE_STDLIBCORE_EXCLUSIVITY_CHECKING=FALSE",

            "SWIFT_ANDROID_DEPLOY_DEVICE_PATH=/data/local/tmp",
            "SWIFT_SDK_ANDROID_ARCHITECTURES=\"\(AndroidArchs.all.map { $0.swiftArch }.joined(separator: ";"))\"",
            "SWIFT_BUILD_SOURCEKIT=FALSE",
            "SWIFT_ENABLE_SOURCEKIT_TESTS=FALSE",
            "SWIFT_SOURCEKIT_USE_INPROC_LIBRARY=TRUE",
            "SWIFT_STDLIB_ASSERTIONS=FALSE",
            "SWIFT_INCLUDE_TOOLS=TRUE",
            "SWIFT_BUILD_REMOTE_MIRROR=TRUE",
            "SWIFT_STDLIB_SIL_DEBUGGING=FALSE",
            "SWIFT_BUILD_DYNAMIC_STDLIB=FALSE",
            "SWIFT_BUILD_STATIC_STDLIB=FALSE",
            "SWIFT_BUILD_DYNAMIC_SDK_OVERLAY=FALSE",
            "SWIFT_BUILD_STATIC_SDK_OVERLAY=FALSE",
            "SWIFT_BUILD_PERF_TESTSUITE=FALSE",
            "SWIFT_BUILD_EXTERNAL_PERF_TESTSUITE=FALSE",
            "SWIFT_BUILD_EXAMPLES=FALSE",
            "SWIFT_INCLUDE_TESTS=FALSE",
            "SWIFT_INCLUDE_DOCS=FALSE",
            "SWIFT_INSTALL_COMPONENTS='autolink-driver;compiler;clang-builtin-headers;stdlib;swift-remote-mirror;sdk-overlay;license'",
            "SWIFT_ENABLE_LLD_LINKER=FALSE",
            "SWIFT_ENABLE_GOLD_LINKER=TRUE",
            "SWIFT_ENABLE_DISPATCH=false",
            "LIBDISPATCH_CMAKE_BUILD_TYPE=Release",
            "SWIFT_OVERLAY_TARGETS=''",
            "SWIFT_HOST_VARIANT=macosx",
            "SWIFT_HOST_VARIANT_SDK=OSX",
            "SWIFT_ENABLE_IOS32=false",
            "SWIFT_SDKS='ANDROID;OSX'",
            "SWIFT_PRIMARY_VARIANT_SDK=ANDROID",
            "SWIFT_AST_VERIFIER=FALSE",
            "SWIFT_RUNTIME_ENABLE_LEAK_CHECKER=FALSE",
            "SWIFT_STDLIB_SUPPORT_BACK_DEPLOYMENT=FALSE",
            "LLVM_LIT_ARGS=-sv",
            "LLVM_ENABLE_ASSERTIONS=TRUE",
            "COVERAGE_DB=",
        ]
    }
}
