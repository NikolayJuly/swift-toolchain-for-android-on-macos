// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "swift-builder",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "SwiftBuilder",
            targets: [
                "SwiftBuilder",
            ]),
        .executable(
            name: "swiftc-android",
            targets: [
                "SwiftcAndroid",
            ]),
        .executable(
            name: "swift-on-android-test",
            targets: [
                "SampleAndroidBinary"
            ]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),

        // Log + Console
        .package(url: "https://github.com/crspybits/swift-log-file.git", from: "0.1.0"),
        .package(url: "https://github.com/vapor/console-kit", from: "4.5.0"),

        // Tools
        .package(url: "https://github.com/NikolayJuly/drain-work-pool.git", from: "2.0.0"),
    ],
    targets: [
        .target(name: "AndroidConfig",
                dependencies: []),
        .target(name: "FoundationExtension",
                dependencies: [
                    .product(name: "Logging", package: "swift-log"),
                ]),
        .target(name: "HostConfig",
                dependencies: ["FoundationExtension"]),
        .executableTarget(name: "SampleAndroidBinary"),
        .target(
            name: "Shell",
            dependencies: [
                "FoundationExtension",
                .product(name: "ConsoleKit", package: "console-kit"),
                .product(name: "Logging", package: "swift-log"),
            ]),
        .executableTarget(
            name: "SwiftBuilder",
            dependencies: [
                "AndroidConfig",
                "FoundationExtension",
                "HostConfig",
                "Shell",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ConsoleKit", package: "console-kit"),
                .product(name: "FileLogging", package: "swift-log-file"),
                .product(name: "WorkPoolDraning", package: "drain-work-pool"),
            ],
            exclude: [
                "Repos/HowToGetCommitHashes.md",
            ]),
        .executableTarget(
            name: "SwiftcAndroid",
            dependencies: [
                "AndroidConfig",
                "FoundationExtension",
                "HostConfig",
                "Shell",
                .product(name: "ConsoleKit", package: "console-kit"),
                .product(name: "Logging", package: "swift-log"),
            ]),
    ]
)
