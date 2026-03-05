![Swift 6.0](https://img.shields.io/badge/swift-6.0-orange)
![SPM](https://img.shields.io/badge/Package%20Manager-SPM-informational)
![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-blue)

# SwiftFulcrum

SwiftFulcrum is a pure Swift, actor-based client for Fulcrum WebSocket JSON-RPC servers on the Bitcoin Cash network.

## Requirements

- Swift 6.0+
- iOS 18+, macOS 15+, watchOS 11+, tvOS 18+, visionOS 2+

## Installation (Swift Package Manager)

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/58opals/SwiftFulcrum.git", .upToNextMajor(from: "0.5.0"))
]
```

## Quick Start

```swift
import SwiftFulcrum

Task {
    do {
        let fulcrum = try await SwiftFulcrum.Client()
        try await fulcrum.start()

        let response = try await fulcrum.submit(
            method: .blockchain(.headers(.getTip)),
            responseType: SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Headers.GetTip.self
        )

        if let tip = response.extractRegularResponse() {
            print("Best header height: \(tip.height)")
        }

        await fulcrum.stop()
    } catch {
        print("Connection error: \(error)")
    }
}
```

## Core Capabilities

- Typed RPC requests via `SwiftFulcrum.RPC.Method`
- Typed response decoding via `SwiftFulcrum.RPC.Response.ResultModel.*`
- Automatic protocol negotiation (`server.version`)
- Reconnect/failover with subscription recovery
- Connection state streams and diagnostics snapshots

## Resource Files

The package includes server catalog resources used at runtime:

- `Sources/SwiftFulcrum/Network/WebSocket/servers.mainnet.json`
- `Sources/SwiftFulcrum/Network/WebSocket/servers.testnet.json`
