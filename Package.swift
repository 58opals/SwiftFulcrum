// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftFulcrum",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .watchOS(.v26),
        .tvOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "SwiftFulcrum",
            targets: ["SwiftFulcrum"]),
    ],
    targets: [
        .target(
            name: "SwiftFulcrum",
            resources: [
                .process("Network/WebSocket/servers.json")
            ]
        ),
        .testTarget(
            name: "SwiftFulcrumTests",
            dependencies: ["SwiftFulcrum"]
        )
    ]
)
