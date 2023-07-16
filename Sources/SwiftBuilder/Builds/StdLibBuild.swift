import AndroidConfig
import Foundation

struct StdLibBuild: BuildItemForAndroidArch, NinjaBuildableItem {

    var repo: Checkoutable { Repos.swift }

    let arch: AndroidArch

    init(arch: AndroidArch,
         dependencies: [String: BuildableItemDependency]) {
        self.arch = arch
        self.dependencies = dependencies
    }

    // MARK: BuildableItem

    let dependencies: [String: BuildableItemDependency]

    var underlyingRepo: BuildableItemRepo? {
        BuildableItemRepo(checkoutable: swift.repo,
                          patchFileName: "stdlib.patch")
    }

    func cmakeCacheEntries(config: BuildConfig) -> [String] {
        [
            "ANDROID_ABI=" + arch.ndkABI,
            "ANDROID_PLATFORM=android-" + config.androidApiLevel,
            "CMAKE_TOOLCHAIN_FILE=" + config.cmakeToolchainFile,

            // LLVM_DIR come form dependency

            "SWIFT_HOST_VARIANT_SDK=ANDROID",
            "SWIFT_HOST_VARIANT_ARCH=" + arch.swiftArch,
            "SWIFT_SDKS=\"ANDROID\"",
            "SWIFT_STANDARD_LIBRARY_SWIFT_FLAGS='-sdk;\(config.ndkToolchain)/sysroot'", // also might add `;-v` for verbose

            "SWIFT_ENABLE_EXPERIMENTAL_CONCURRENCY=TRUE",

            "SWIFT_STDLIB_SINGLE_THREADED_RUNTIME=FALSE",

            // SWIFT_PATH_TO_LIBDISPATCH_SOURCE come from LibDispatch dependency

            "SWIFT_BUILD_DYNAMIC_SDK_OVERLAY=TRUE",
            "SWIFT_BUILD_STATIC_SDK_OVERLAY=FALSE",

            "SWIFT_BUILD_TEST_SUPPORT_MODULES=FALSE",

            "SWIFT_INCLUDE_TOOLS=NO",
            "SWIFT_INCLUDE_TESTS=FALSE",
            "SWIFT_INCLUDE_DOCS=NO",

            "SWIFT_BUILD_SYNTAXPARSERLIB=NO",
            "SWIFT_BUILD_SOURCEKIT=NO",

            "SWIFT_ENABLE_LLD_LINKER=FALSE",
            "SWIFT_ENABLE_GOLD_LINKER=TRUE",

            "SWIFT_ENABLE_DISPATCH=true",

            "SWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER=YES",
            "SWIFT_NATIVE_SWIFT_TOOLS_PATH=\(config.buildLocation(for: swift).path)/bin",

            // TODO: These pathes form pre-installed libxml2, so might be needed to build it before
            "LIBXML2_LIBRARY=/opt/homebrew/Cellar/libxml2/2.10.3/lib",
            "LIBXML2_INCLUDE_DIR=/opt/homebrew/Cellar/libxml2/2.10.3/include",
        ]
    }

    func buildSteps() -> [BuildStep] {
        [
            ConfigureRepoStep(buildableItem: self),
            NinjaBuildStep(buildableRepo: self),
            SwiftLibsInstallStep(buildItem: self)
        ]
    }

    // MARK: Private

    private var swift: BuildRepoItem { Builds.swift }
}
