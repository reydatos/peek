// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PeekCore",
    platforms: [.iOS("27.0"), .macOS(.v14)],
    products: [.library(name: "PeekCore", targets: ["PeekCore"])],
    targets: [
        .target(name: "PeekCore"),
        .testTarget(name: "PeekCoreTests", dependencies: ["PeekCore"]),
    ]
)
