// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VisionDeadlock",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "VisionDeadlock",
            resources: [
                .copy("Resources"),
            ],
            swiftSettings: [
                // With `swift-tools-version: 6.0` or greater, this must be
                // .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
    ]
)
