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
                "Shell"
            ]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/console-kit", from: "4.5.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftBuilder",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ConsoleKit", package: "console-kit"),
                "Shell",
            ]),
        .target(
            name: "Shell",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ConsoleKit", package: "console-kit"),
            ]),
    ]
)
