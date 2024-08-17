// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SwiftFulcrum",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
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
