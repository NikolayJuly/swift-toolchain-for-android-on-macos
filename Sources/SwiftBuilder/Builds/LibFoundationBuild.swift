import Foundation

struct LibFoundationBuild: NinjaBuildableItem {
    init(arch: AndroidArch,
         foundationRepo: FoundationRepo,
         dispatch: LibDispatchBuild,
         swift: SwiftBuild,
         stdlib: StdLibBuild,
         icu: ICUBuild,
         curl: LibCurlBuild,
         libXml2: LibXml2Build) {
        self.arch = arch
        self.foundationRepo = foundationRepo
        self.dispatch = dispatch
        self.swift = swift
        self.stdlib = stdlib
        self.icu = icu
        self.curl = curl
        self.libXml2 = libXml2
    }

    // TODO: I use this approach a lot. I need couple protocols with default implementation. Build on top of repo and build with arch on top of repo
    var name: String { foundationRepo.repoName + "-" + arch.name }

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.location(for: foundationRepo)
    }

    func cmakeCacheEntries(config: BuildConfig) -> [String] {
        let cmakeSwiftFlags = [
            "-resource-dir \(config.buildLocation(for: stdlib).path)/lib/swift",
            "-Xcc --sysroot=\(config.ndkToolchain)/sysroot",

            // I got error, that can't find start stop files - https://stackoverflow.com/questions/69795531/after-ndk22-upgrade-the-build-fails-with-cannot-open-crtbegin-so-o-crtend-so
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
            "ICU_I18N_LIBRARY_RELEASE=\(icuInstallPath)/lib/libicui18nswift.so",
            "ICU_UC_LIBRARY_RELEASE=\(icuInstallPath)/lib/libicuucswift.so",

            // XML
            "LIBXML2_INCLUDE_DIR=\(libXmlInstallPath)/include/libxml2",
            "LIBXML2_LIBRARY=\(libXmlInstallPath)/lib/libxml2.so",

            // CURL
            "CURL_INCLUDE_DIR=\(curlInstallPath)/include",
            "CURL_LIBRARY=\(curlInstallPath)/lib/libcurl.so",
        ]
    }

    private let arch: AndroidArch
    private let foundationRepo: FoundationRepo
    private let dispatch: LibDispatchBuild
    private let swift: SwiftBuild
    private let stdlib: StdLibBuild
    private let icu: ICUBuild
    private let curl: LibCurlBuild
    private let libXml2: LibXml2Build
}
