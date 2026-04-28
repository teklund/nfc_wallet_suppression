// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "nfc_wallet_suppression",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "nfc-wallet-suppression", targets: ["nfc_wallet_suppression"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "nfc_wallet_suppression",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ]
            // PassKit is a system framework and is autolinked via `import PassKit` —
            // no linkerSettings needed for Swift targets.
        ),
    ]
)
