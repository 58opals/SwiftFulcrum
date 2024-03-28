// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SwiftFulcrum",
    products: [
        .library(
            name: "SwiftFulcrum",
            targets: ["SwiftFulcrum"]),
    ],
    targets: [
        .target(
            name: "SwiftFulcrum"),
        .testTarget(
            name: "SwiftFulcrumTests",
            dependencies: ["SwiftFulcrum"]),
    ]
)
