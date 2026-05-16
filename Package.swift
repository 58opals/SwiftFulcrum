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
    dependencies: [
        .package(url: "https://github.com/58opals/OpalDiagnostics.git", branch: "develop")
    ],
    targets: [
        .target(
            name: "SwiftFulcrum",
            dependencies: [
                .product(name: "OpalDiagnostics", package: "OpalDiagnostics")
            ],
            resources: [
                .process("Network/WebSocket/servers.mainnet.json"),
                .process("Network/WebSocket/servers.testnet.json"),
                .process("Network/WebSocket/servers.chipnet.json")
            ]
        ),
        .target(
            name: "SwiftFulcrumTestSupport",
            dependencies: ["SwiftFulcrum"],
            path: "Tests/SwiftFulcrumTestSupport"
        ),
        .testTarget(
            name: "SwiftFulcrumLocalTests",
            dependencies: [
                "SwiftFulcrum",
                "SwiftFulcrumTestSupport",
                .product(name: "OpalDiagnostics", package: "OpalDiagnostics")
            ],
            path: "Tests/SwiftFulcrumLocalTests"
        ),
        .testTarget(
            name: "SwiftFulcrumNetworkTests",
            dependencies: ["SwiftFulcrum", "SwiftFulcrumTestSupport"],
            path: "Tests/SwiftFulcrumNetworkTests"
        )
    ]
)
