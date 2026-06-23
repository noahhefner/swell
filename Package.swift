// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swell",
    products: [
        .executable(name: "swell", targets: ["swell"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.8.2"),
    ],
    targets: [
        .executableTarget(
            name: "swell",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "SwellTests",
            dependencies: ["swell"]
        ),
        .testTarget(
            name: "SwellIntegrationTests",
            dependencies: ["swell"]
        ),
    ]
)
