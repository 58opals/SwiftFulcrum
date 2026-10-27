// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "SwiftFulcrum",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .watchOS(.v27),
        .tvOS(.v27),
        .visionOS(.v27)
    ],
    products: [
        .library(
            name: "SwiftFulcrum",
            targets: ["SwiftFulcrum"]),
    ],
    dependencies: [
        .package(url: "https://github.com/58opals/OpalDiagnostics.git", revision: "393325d11591bf87c65288f7755337491b4b41b1")
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
