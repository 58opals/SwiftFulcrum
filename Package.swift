// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftFulcrum",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
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
