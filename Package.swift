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
    targets: [
        .target(
            name: "HealthyVibeCore",
            path: "Sources/HealthyVibeCore"
        ),
        .executableTarget(
            name: "HealthyVibe",
            dependencies: ["HealthyVibeCore"],
            path: "Sources/HealthyVibe"
        ),
        .testTarget(
            name: "HealthyVibeCoreTests",
            dependencies: ["HealthyVibeCore"],
            path: "Tests/HealthyVibeCoreTests"
        )
    ]
)
