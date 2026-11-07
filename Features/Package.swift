// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Features",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "Features", targets: ["Features"])
    ],
    dependencies: [
        .package(path: "../JournalCore")
    ],
    targets: [
        .target(
            name: "Features",
            dependencies: [
                .product(name: "JournalCore", package: "JournalCore")
            ]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: ["Features"]
        ),
    ]
)
