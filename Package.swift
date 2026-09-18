// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Deck",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Deck",
            targets: ["Deck"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Deck",
            dependencies: [],
            path: "Sources/Deck"
        )
    ]
)
