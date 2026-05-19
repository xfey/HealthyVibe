// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HealthyVibe",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "HealthyVibe", targets: ["HealthyVibe"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "HealthyVibeCore",
            path: "Sources/HealthyVibeCore"
        ),
        .target(
            name: "HealthyVibeStorage",
            dependencies: [
                "HealthyVibeCore",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/HealthyVibeStorage"
        ),
        .target(
            name: "HealthyVibeAgents",
            path: "Sources/HealthyVibeAgents"
        ),
        .executableTarget(
            name: "HealthyVibe",
            dependencies: [
                "HealthyVibeCore",
                "HealthyVibeStorage",
                "HealthyVibeAgents"
            ],
            path: "Sources/HealthyVibe"
        ),
        .testTarget(
            name: "HealthyVibeCoreTests",
            dependencies: ["HealthyVibeCore"],
            path: "Tests/HealthyVibeCoreTests"
        ),
        .testTarget(
            name: "HealthyVibeStorageTests",
            dependencies: [
                "HealthyVibeCore",
                "HealthyVibeStorage"
            ],
            path: "Tests/HealthyVibeStorageTests"
        ),
        .testTarget(
            name: "HealthyVibeAgentsTests",
            dependencies: ["HealthyVibeAgents"],
            path: "Tests/HealthyVibeAgentsTests"
        )
    ]
)
