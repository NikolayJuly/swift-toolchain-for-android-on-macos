import AndroidConfig
import Foundation
import Logging
import Shell

struct LibDispatchBuild: BuildItemForAndroidArch, NinjaBuildableItem {

    var repo: Checkoutable { Repos.libDispatchRepo }

    let arch: AndroidArch

    init(arch: AndroidArch,
         stdlib: BuildableItem) {
        self.arch = arch
        self.stdlib = stdlib
    }

    func cmakeCacheEntries(config: BuildConfig) -> [String] {
        let cmakeSwiftFlags = [
            "-resource-dir \(config.buildLocation(for: stdlib).path)/lib/swift",
            "-Xcc --sysroot=\(config.ndk.toolchainPath)/sysroot",

            // I got error, that can't find start stop files - https://stackoverflow.com/questions/69795531/after-ndk22-upgrade-the-build-fails-with-cannot-open-crtbegin-so-o-crtend-so
            // More detailed explanation - https://github.com/NikolayJuly/swift-toolchain-for-android-on-macos/issues/1#issuecomment-1426774354
            "-Xclang-linker -nostartfiles",

            "-Xclang-linker --sysroot=\(config.ndk.sysrootLibPath)/\(arch.ndkLibArchName)/\(config.androidApiLevel)",
            "-Xclang-linker --gcc-toolchain=\(config.ndk.toolchainPath)",
            "-tools-directory \(config.ndk.toolchainPath)/bin",

            //"-Xclang-linker -v",
            //"-v",
        ]

        let cFlags: [String] = [
            //"-v",
        ]

        let cxxFlags: [String] = [
            //"-v",
        ]

        let cmakeSwiftFlagsString = cmakeSwiftFlags.joined(separator: " ")
        let cFlagsString = cFlags.joined(separator: " ")
        let cxxFlagsString = cxxFlags.joined(separator: " ")

        return [
            "ANDROID_ABI=" + arch.ndkABI,
            "ANDROID_PLATFORM=android-" + config.androidApiLevel,
            "CMAKE_TOOLCHAIN_FILE=" + config.cmakeToolchainFile,

            "ENABLE_TESTING=NO",
            "ENABLE_SWIFT=YES",

            "CMAKE_Swift_COMPILER=\(config.buildLocation(for: swift).path)/bin/swiftc",
            "CMAKE_Swift_COMPILER_FORCED=true",

            "CMAKE_Swift_COMPILER_TARGET=\(arch.swiftTarget)",

            "CMAKE_Swift_FLAGS=\"\(cmakeSwiftFlagsString)\"",
            "CMAKE_C_FLAGS=\"\(cFlagsString)\"",
            "CMAKE_CXX_FLAGS=\"\(cxxFlagsString)\"",

            "CMAKE_BUILD_WITH_INSTALL_RPATH=true",
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

    private var swift: BuildableItem { Builds.swift }
    private let stdlib: BuildableItem
}

