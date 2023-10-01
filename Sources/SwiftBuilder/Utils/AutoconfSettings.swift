import AndroidConfig
import Foundation

extension BuildConfig {
    func clangPath(for arch: AndroidArch) -> String {
        ndk.toolchainPath + "/bin/\(arch.clangFilenamePrefix)\(androidApiLevel)-clang"
    }

    func clangPpPath(for arch: AndroidArch) -> String {
        ndk.toolchainPath + "/bin/\(arch.clangFilenamePrefix)\(androidApiLevel)-clang++"
    }
}

final class AutoconfSettings {
    static func compilerAndHostExports(config: BuildConfig, arch: AndroidArch) -> [String] {
        [
            "CC='\(config.clangPath(for: arch))'",
            "CXX='\(config.clangPpPath(for: arch))'",
            "CHOST=\(arch.cHost)",
        ]
    }

    static func clangFlags(arch: AndroidArch) -> [String] {
        [
            "CFLAGS=' -Os -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing \(arch.cFlag)'",
            "CXXFLAGS=' -Os -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -frtti -fexceptions -std=c++11 -Wno-error=unused-command-line-argument \(arch.cFlag)'",
            "CPPFLAGS=' -Os -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing  \(arch.cFlag)'",
        ]
    }

    private init() {}
}

extension AndroidArch {
    var cHost: String {
        switch self {
        case AndroidArchs.arm64:
            return "aarch64-linux-android"
        case AndroidArchs.arm7:
            return "arm-linux-androideabi"
        case AndroidArchs.x86:
            return "i686-linux-android"
        case AndroidArchs.x86_64:
            return "x86_64-linux-android"
        default:
            fatalError("Unsupported arch \(name)")
        }
    }
}

private extension AndroidArch {
    var cFlag: String {
        switch self {
        case AndroidArchs.arm64:
            return ""
        case AndroidArchs.arm7:
            return "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
        case AndroidArchs.x86:
            return "-march=i686 -mssse3 -mfpmath=sse -m32"
        case AndroidArchs.x86_64:
            return "-march=x86-64"
        default:
            fatalError("Unsupported arch \(name)")
        }
    }

    var clangFilenamePrefix: String {
        switch self {
        case AndroidArchs.arm64:
            return "aarch64-linux-android"
        case AndroidArchs.arm7:
            return "armv7a-linux-androideabi"
        case AndroidArchs.x86:
            return "i686-linux-android"
        case AndroidArchs.x86_64:
            return "x86_64-linux-android"
        default:
            fatalError("Unsupported arch \(name)")
        }
    }
}
