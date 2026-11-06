// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "JournalCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "JournalCore", targets: ["JournalCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.0")
    ],
    targets: [
        .target(
            name: "JournalCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ]
        ),
        .testTarget(
            name: "JournalCoreTests",
            dependencies: ["JournalCore"]
        ),
    ]
)
