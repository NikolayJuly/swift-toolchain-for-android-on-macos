import Foundation

enum AndroidArchs {
    static let all: [AndroidArch] = [
        arm64,
        arm7,
        x86,
        x86_64,
    ]

    static let arm64 = AndroidArch(name: "aarch64",
                                   ndkABI: "arm64-v8a",
                                   ndkPlatform: "arch-arm64",
                                   ndkLibArchName: "aarch64-linux-android",
                                   swiftArch: "aarch64",
                                   swiftTarget: "aarch64-unknown-linux-android")

    static let arm7 = AndroidArch(name: "armv7a",
                                  ndkABI: "armeabi-v7a",
                                  ndkPlatform: "arch-arm",
                                  ndkLibArchName: "arm-linux-androideabi",
                                  swiftArch: "armv7",
                                  swiftTarget: "armv7-unknown-linux-androideabi")

    static let x86 = AndroidArch(name: "x86",
                                 ndkABI: "x86",
                                 ndkPlatform: "arch-x86",
                                 ndkLibArchName: "i686-linux-android",
                                 swiftArch: "i686",
                                 swiftTarget: "i686-unknown-linux-android")

    static let x86_64 = AndroidArch(name: "x86_64",
                                    ndkABI: "x86_64",
                                    ndkPlatform: "arch-x86_64",
                                    ndkLibArchName: "x86_64-linux-android",
                                    swiftArch: "x86_64",
                                    swiftTarget: "x86_64-unknown-linux-android")
}

struct AndroidArch: Hashable {
    let name: String
    let ndkABI: String
    let ndkPlatform: String
    let ndkLibArchName: String
    let swiftArch: String
    let swiftTarget: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.ndkABI == rhs.ndkABI
    }
}
