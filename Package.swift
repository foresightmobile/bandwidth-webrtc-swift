// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bandwidth-webrtc",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BandwidthWebRTC",
            targets: ["BandwidthWebRTC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/foresightmobile/json-rpc-websockets.git", .branch("dev")),
        .package(url: "https://github.com/webrtc-sdk/Specs.git", from: "104.5112.04")
    ],
    targets: [
        .target(
            name: "BandwidthWebRTC",
            dependencies: [
                .product(name: "JSONRPCWebSockets", package: "json-rpc-websockets"),
                .product(name: "WebRTC", package: "Specs")
            ],
            resources: [.copy("Settings.plist")],
            swiftSettings: [
              .define("SPM")
            ]
        ),
        .testTarget(
            name: "BandwidthWebRTCTests",
            dependencies: ["BandwidthWebRTC"],
            resources: [.copy("Settings.plist")],
            swiftSettings: [
              .define("SPM")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
