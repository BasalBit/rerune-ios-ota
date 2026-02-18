// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "rerune-ios-ota",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ReRuneCore",
            targets: ["ReRuneCore"]
        ),
        .library(
            name: "ReRuneSwiftUI",
            targets: ["ReRuneSwiftUI"]
        )
    ],
    targets: [
        .target(
            name: "ReRuneCore",
            path: "Sources/ReRuneCore"
        ),
        .target(
            name: "ReRuneSwiftUI",
            dependencies: ["ReRuneCore"],
            path: "Sources/ReRuneSwiftUI"
        ),
        .testTarget(
            name: "ReRuneCoreTests",
            dependencies: ["ReRuneCore"],
            path: "Tests/ReRuneCoreTests"
        ),
        .testTarget(
            name: "ReRuneSwiftUITests",
            dependencies: ["ReRuneSwiftUI", "ReRuneCore"],
            path: "Tests/ReRuneSwiftUITests"
        )
    ]
)
