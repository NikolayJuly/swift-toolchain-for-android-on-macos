import Foundation

public enum AndroidArchs {
    public static let all: [AndroidArch] = [
        arm64,
        arm7,
        x86,
        x86_64,
    ]

    public static let arm64 = AndroidArch(name: "aarch64",
                                          ndkABI: "arm64-v8a",
                                          ndkPlatform: "arch-arm64",
                                          ndkLibArchName: "aarch64-linux-android",
                                          swiftArch: "aarch64",
                                          swiftTarget: "aarch64-unknown-linux-android")

    public static let arm7 = AndroidArch(name: "armv7a",
                                         ndkABI: "armeabi-v7a",
                                         ndkPlatform: "arch-arm",
                                         ndkLibArchName: "arm-linux-androideabi",
                                         swiftArch: "armv7",
                                         swiftTarget: "armv7-unknown-linux-androideabi")

    public static let x86 = AndroidArch(name: "x86",
                                        ndkABI: "x86",
                                        ndkPlatform: "arch-x86",
                                        ndkLibArchName: "i686-linux-android",
                                        swiftArch: "i686",
                                        swiftTarget: "i686-unknown-linux-android")

    public static let x86_64 = AndroidArch(name: "x86_64",
                                           ndkABI: "x86_64",
                                           ndkPlatform: "arch-x86_64",
                                           ndkLibArchName: "x86_64-linux-android",
                                           swiftArch: "x86_64",
                                           swiftTarget: "x86_64-unknown-linux-android")
}

public struct AndroidArch: Hashable {
    public let name: String
    public let ndkABI: String
    public let ndkPlatform: String
    public let ndkLibArchName: String
    public let swiftArch: String
    public let swiftTarget: String

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.ndkABI == rhs.ndkABI
    }
}
