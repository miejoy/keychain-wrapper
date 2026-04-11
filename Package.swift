// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "keychain-wrapper",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .tvOS(.v14),
        .watchOS(.v7),
    ],
    products: [
        .library(
            name: "KeychainWrapper",
            targets: ["KeychainWrapper"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "KeychainWrapper",
            dependencies: []),
        .testTarget(
            name: "KeychainWrapperTests",
            dependencies: ["KeychainWrapper"]),
    ]
)
