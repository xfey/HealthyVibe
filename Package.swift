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
        .executableTarget(
            name: "HealthyVibe",
            path: "Sources/HealthyVibe"
        )
    ]
)
