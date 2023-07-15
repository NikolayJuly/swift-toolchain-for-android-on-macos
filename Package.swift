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
                "Shell",
            ]),
        .executable(
            name: "swiftc-android",
            targets: [
                "Shell",
                "SwiftcAndroid",
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
        .target(name: "FoundationExtension",
                dependencies: []),
        .target(name: "HostConfig",
                dependencies: ["FoundationExtension"]),
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
                "FoundationExtension",
                "HostConfig",
                "Shell",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ConsoleKit", package: "console-kit"),
                .product(name: "Logging", package: "swift-log"),
            ]),
    ]
)
