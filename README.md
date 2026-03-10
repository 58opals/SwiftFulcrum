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

        let tip = try await fulcrum.request(
            method: .blockchain(.headers(.getTip)),
            responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self
        )
        print("Best header height: \(tip.height)")

        let (initial, updates, cancel) = try await fulcrum.subscribe(
            method: .blockchain(.headers(.subscribe)),
            initialType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
            notificationType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self
        )
        print("Subscribed from height: \(initial.height)")

        for try await update in updates.prefix(1) {
            print("Received \(update.blocks.count) new header(s)")
        }

        await cancel()
        await fulcrum.stop()
    } catch {
        print("Connection error: \(error)")
    }
}
```

## Core Capabilities

- Typed RPC requests via `SwiftFulcrum.RPC.Method`
- Typed response decoding via `SwiftFulcrum.RPC.Response.Result.*`
- Automatic protocol negotiation (`server.version`)
- Reconnect/failover with subscription recovery
- Connection state streams and diagnostics snapshots

## Subscription Recovery

Active `subscribe(...)` registrations are persisted and restored by `SwiftFulcrum.Client` / `FulcrumNetworkClient`
after failover or an explicit `reconnect()`. Downstream callers should not add a second manual resubscribe layer.

## Resource Files

The package includes server catalog resources used at runtime:

- `Sources/SwiftFulcrum/Network/WebSocket/servers.mainnet.json`
- `Sources/SwiftFulcrum/Network/WebSocket/servers.testnet.json`
