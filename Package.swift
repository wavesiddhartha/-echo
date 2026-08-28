// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Echo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Echo",
            targets: ["Echo"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Echo",
            dependencies: [],
            path: "Sources/Echo"
        ),
        .testTarget(
            name: "EchoTests",
            dependencies: ["Echo"],
            path: "Tests/EchoTests"
        )
    ]
)
