// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GitCthulhu",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        // Main application executable
        .executable(
            name: "GitCthulhu",
            targets: ["GitCthulhu"]
        ),
        // Core Git functionality library
        .library(
            name: "GitCore",
            targets: ["GitCore"]
        ),
        // Shared UI components library
        .library(
            name: "UIKit",
            targets: ["UIKit"]
        ),
        // Utilities library
        .library(
            name: "Utilities",
            targets: ["Utilities"]
        )
    ],
    dependencies: [
        // Testing framework
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.4.0")
        // Note: libgit2 dependency will be added in future sprint
    ],
    targets: [
        // MARK: - Main Application
        .executableTarget(
            name: "GitCthulhu",
            dependencies: [
                "GitCore",
                "UIKit",
                "Utilities"
            ],
            path: "Sources/GitCthulhu",
            resources: [
                .process("Resources")
            ]
        ),

        // MARK: - Core Libraries
        .target(
            name: "GitCore",
            dependencies: [
                "Utilities"
                // SwiftGit2 will be added in future sprint
            ],
            path: "Sources/GitCore"
        ),

        .target(
            name: "UIKit",
            dependencies: [
                "GitCore",
                "Utilities"
            ],
            path: "Sources/UIKit"
        ),

        .target(
            name: "Utilities",
            dependencies: [],
            path: "Sources/Utilities"
        ),

        // MARK: - Tests
        .testTarget(
            name: "GitCthulhuTests",
            dependencies: [
                "GitCthulhu",
                "GitCore",
                "UIKit",
                "Utilities",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/GitCthulhuTests"
        ),

        .testTarget(
            name: "GitCoreTests",
            dependencies: [
                "GitCore",
                "Utilities",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/GitCoreTests"
        ),

        .testTarget(
            name: "UITests",
            dependencies: [
                "UIKit",
                "GitCore",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/UITests"
        )
    ]
)
