// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Alars",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "alars",
            targets: ["Alars"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut", from: "2.3.0")
    ],
    targets: [
        .executableTarget(
            name: "Alars",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Rainbow", package: "Rainbow"),
                .product(name: "ShellOut", package: "ShellOut")
            ]
        ),
        .testTarget(
            name: "AlarsTests",
            dependencies: ["Alars"]
        )
    ]
)