// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swiftcompress",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "swiftcompress",
            targets: ["swiftcompress"]
        )
    ],
    dependencies: [
        // ArgumentParser for CLI argument parsing
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        // Main executable target
        .executableTarget(
            name: "swiftcompress",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources",
            exclude: [
                // Exclude test-related files
            ]
        ),

        // Test target
        .testTarget(
            name: "swiftcompressTests",
            dependencies: ["swiftcompress"],
            path: "Tests"
        ),
    ]
)
