// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sLaunchctl",
    platforms: [.macOS(.v10_10)],
    products: [
        .library(
            name: "sLaunchctl",
            targets: ["sLaunchctl"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alkenso/SwiftConvenience.git", from: "0.0.17"),
    ],
    targets: [
        .target(
            name: "sLaunchctl",
            dependencies: ["SwiftConvenience"]
        ),
    ]
)
