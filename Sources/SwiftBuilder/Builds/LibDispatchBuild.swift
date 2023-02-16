import Foundation

struct LibDispatchBuild: BuildableItem {

    init(arch: AndroidArch,
         libDispatchRepo: LibDispatchRepo,
         swift: SwiftRepo,
         stdlib: StdLibBuild) {
        self.arch = arch
        self.libDispatchRepo = libDispatchRepo
        self.swift = swift
        self.stdlib = stdlib
    }

    var name: String { "libDispatch-\(arch.name)" }

    var underlyingRepo: BuildableItemRepo? {
        BuildableItemRepo(checkoutable: libDispatchRepo, patchFileName: "libDispatch")
    }

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.location(for: libDispatchRepo)
    }

    func cmakeCacheEntries(config: BuildConfig) -> [String] {
        let cmakeSwiftFlags = [
            "-resource-dir \(config.buildLocation(for: stdlib).path)/lib/swift",
            "-Xcc --sysroot=\(config.ndkToolchain)/sysroot",

            // Follow this unwer, otherwise, I got error, that can't find start stop files - https://stackoverflow.com/questions/69795531/after-ndk22-upgrade-the-build-fails-with-cannot-open-crtbegin-so-o-crtend-so
            // More detailed explanation - https://github.com/NikolayJuly/swift-toolchain-for-android-on-macos/issues/1#issuecomment-1426774354
            "-Xclang-linker -nostartfiles",

            "-Xclang-linker --sysroot=\(config.ndkToolchain)/sysroot/usr/lib/\(arch.ndkLibArchName)/\(config.androidApiLevel)",
            "-Xclang-linker --gcc-toolchain=\(config.ndkToolchain)",
            "-tools-directory \(config.ndkToolchain)/bin",

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

    // MARK: Private

    private let arch: AndroidArch
    private let swift: SwiftRepo
    private let stdlib: StdLibBuild
    private let libDispatchRepo: LibDispatchRepo
}
