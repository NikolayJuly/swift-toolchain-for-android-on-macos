import AndroidConfig
import Foundation

struct LibFoundationBuild: BuildItemForAndroidArch, NinjaBuildableItem {

    let arch: AndroidArch

    var repo: Checkoutable { Repos.foundationRepo }

    init(arch: AndroidArch,
         dispatch: BuildableItem,
         stdlib: BuildableItem,
         icu: BuildableItem,
         curl: BuildableItem,
         libXml2: BuildableItem) {
        self.arch = arch
        self.dispatch = dispatch
        self.stdlib = stdlib
        self.icu = icu
        self.curl = curl
        self.libXml2 = libXml2
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

        let dispatchBuild = config.buildLocation(for: dispatch).path

        let icuInstallPath = config.installLocation(for: icu).path
        let curlInstallPath = config.installLocation(for: curl).path
        let libXmlInstallPath = config.installLocation(for: libXml2).path

        return [
            "ANDROID_ABI=" + arch.ndkABI,
            "ANDROID_PLATFORM=android-" + config.androidApiLevel,
            "CMAKE_TOOLCHAIN_FILE=" + config.cmakeToolchainFile,

            "ENABLE_TESTING=NO",

            "CMAKE_Swift_COMPILER=\(config.buildLocation(for: swift).path)/bin/swiftc",
            "CMAKE_Swift_COMPILER_FORCED=true",

            "CMAKE_Swift_COMPILER_TARGET=\(arch.swiftTarget)",

            "CMAKE_Swift_FLAGS=\"\(cmakeSwiftFlagsString)\"",
            "CMAKE_C_FLAGS=\"\(cFlagsString)\"",
            "CMAKE_CXX_FLAGS=\"\(cxxFlagsString)\"",

            "CMAKE_BUILD_WITH_INSTALL_RPATH=true",
            "CMAKE_HAVE_LIBC_PTHREAD=YES",

            // Dispatch
            "dispatch_DIR=\(dispatchBuild)/cmake/modules",

            // ICU
            "ICU_LIBRARY=\(icuInstallPath)/lib",
            "ICU_INCLUDE_DIR=\(icuInstallPath)/include",
            "ICU_I18N_LIBRARY_RELEASE=\(icuInstallPath)/lib/libicui18n.so",
            "ICU_UC_LIBRARY_RELEASE=\(icuInstallPath)/lib/libicuuc.so",

            // XML
            "LIBXML2_INCLUDE_DIR=\(libXmlInstallPath)/include/libxml2",
            "LIBXML2_LIBRARY=\(libXmlInstallPath)/lib/libxml2.so",

            // CURL
            "CURL_INCLUDE_DIR=\(curlInstallPath)/include",
            "CURL_LIBRARY=\(curlInstallPath)/lib/libcurl.so",
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

    private let dispatch: BuildableItem
    private var swift: BuildableItem { Builds.swift }
    private let stdlib: BuildableItem
    private let icu: BuildableItem
    private let curl: BuildableItem
    private let libXml2: BuildableItem
}
