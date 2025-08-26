// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SharedKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SharedKit",
            targets: ["SharedKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SharedKit",
            dependencies: []),
        .testTarget(
            name: "SharedKitTests",
            dependencies: ["SharedKit"]),
    ]
)
