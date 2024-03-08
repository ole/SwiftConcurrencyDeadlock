// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VisionDeadlock",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "VisionDeadlock",
            resources: [
                .copy("Resources"),
            ]
        ),
    ]
)
