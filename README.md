![Swift 6.0](https://img.shields.io/badge/swift-6.0-orange)
![SPM](https://img.shields.io/badge/Package%20Manager-SPM-informational)
![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-blue)

# SwiftFulcrum

SwiftFulcrum is the Swift/BCH network-layer package for talking to public Fulcrum servers over WebSocket JSON-RPC.
It provides an actor-based client, typed RPC methods and result models, reconnect handling, and subscription recovery while staying focused on Fulcrum protocol responsibilities rather than wallet or app-domain logic.

Start with `SwiftFulcrum.Client` when you need typed requests, typed response models, and resilient subscription handling from Apple-platform apps, packages, or tools.

## Purpose and Boundaries

- For Swift/BCH consumers that need a typed Fulcrum adapter, including direct downstream packages such as Opal Base
- Owns Fulcrum transport, protocol modeling, reconnect behavior, bundled server catalogs, and client observability surfaces
- Does not own wallet business logic, persistence, UI, or non-Fulcrum protocol expansion

For deeper package context, audience, and integration expectations, see [docs/context.md](docs/context.md).

## Requirements

- Swift tools version: `6.0`
- Platforms:
  - `iOS 18`
  - `macOS 15`
  - `watchOS 11`
  - `tvOS 18`
  - `visionOS 2`

## Installation (Swift Package Manager)

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/58opals/SwiftFulcrum.git", from: "0.5.5")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "SwiftFulcrum", package: "SwiftFulcrum")
        ]
    )
]
```

If you need unreleased changes, pin a branch or revision instead of a release tag.

## Quick Start

```swift
import SwiftFulcrum

Task {
    do {
        let client = try await SwiftFulcrum.Client()

        let tip = try await client.request(
            method: .blockchain(.headers(.getTip)),
            responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self
        )
        print("Best header height: \(tip.height)")
        await client.stop()
    } catch {
        print("Fulcrum error: \(error)")
    }
}
```

`request(...)` starts the client automatically when idle. `SwiftFulcrum.Client()` uses the bundled mainnet server catalog by default; pass `url:` or `configuration:` when you need a fixed endpoint or different network settings.

## Core Capabilities

- Actor-isolated `SwiftFulcrum.Client` entrypoint for unary requests and streaming subscriptions
- Typed RPC methods via `SwiftFulcrum.RPC.Method`
- Typed response models under `SwiftFulcrum.RPC.Response.Result.*`
- Automatic protocol negotiation plus reconnect and failover with subscription recovery
- Connection-state streams and diagnostics snapshots for observability

## Testing

```bash
swift test
```

Set `SWIFTFULCRUM_RUN_NETWORK=1` to enable the opt-in network test suite.
