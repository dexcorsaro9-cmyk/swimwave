// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwimwaveCore",
    defaultLocalization: "it",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "SwimwaveCore", targets: ["SwimwaveCore"])
    ],
    targets: [
        .target(name: "SwimwaveCore"),
        .testTarget(
            name: "SwimwaveCoreTests",
            dependencies: ["SwimwaveCore"],
            resources: [.copy("Fixtures")]
        )
    ]
)
