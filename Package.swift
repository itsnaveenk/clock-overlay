// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "ClockOverlay",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClockOverlay",
            path: "Sources/ClockOverlay"
        )
    ]
)
