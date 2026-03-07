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
                .process("Network/WebSocket/servers.mainnet.json"),
                .process("Network/WebSocket/servers.testnet.json")
            ]
        ),
        .target(
            name: "SwiftFulcrumTestSupport",
            dependencies: ["SwiftFulcrum"],
            path: "Tests/SwiftFulcrumTestSupport"
        ),
        .testTarget(
            name: "SwiftFulcrumLocalTests",
            dependencies: ["SwiftFulcrum", "SwiftFulcrumTestSupport"],
            path: "Tests/SwiftFulcrumLocalTests"
        ),
        .testTarget(
            name: "SwiftFulcrumNetworkTests",
            dependencies: ["SwiftFulcrum", "SwiftFulcrumTestSupport"],
            path: "Tests/SwiftFulcrumNetworkTests"
        )
    ]
)
