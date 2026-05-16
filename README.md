![Swift 6.2](https://img.shields.io/badge/swift-6.2-orange)
![SPM](https://img.shields.io/badge/Package%20Manager-SPM-informational)
![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-blue)

# SwiftFulcrum

SwiftFulcrum is the Swift/BCH network-layer package for talking to public Fulcrum servers over WebSocket JSON-RPC.
It provides an actor-based client, typed RPC methods and result models, reconnect handling, and subscription recovery while staying focused on Fulcrum protocol responsibilities rather than wallet or app-domain logic.

Start with `SwiftFulcrum.Client` when you need typed requests, typed response models, and resilient subscription handling from Apple-platform apps, packages, or tools.

## Purpose and Boundaries

- For Swift/BCH consumers that need a typed Fulcrum adapter, including direct downstream packages such as Opal Base
- Owns Fulcrum transport, protocol modeling, reconnect behavior, bundled server catalogs, and OpalDiagnostics event emission
- Does not own wallet business logic, persistence, UI, or non-Fulcrum protocol expansion

For deeper package context, audience, and integration expectations, see [docs/context.md](docs/context.md).

## Requirements

- Swift tools version: `6.2`
- Platforms:
  - `iOS 26`
  - `macOS 26`
  - `watchOS 26`
  - `tvOS 26`
  - `visionOS 26`

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

        let tip = try await client.request(SwiftFulcrum.API.blockchain.headers.tip)
        print("Best header height: \(tip.height)")
        await client.stop()
    } catch {
        print("Fulcrum error: \(error)")
    }
}
```

`request(...)` starts the client automatically when idle. `SwiftFulcrum.Client()` uses the bundled mainnet server catalog by default; pass `connectingTo:` or `configuration:` when you need a fixed endpoint or different network settings. Bundled catalogs are available for `mainnet`, `testnet`, and `chipnet`.

```swift
let configuration = SwiftFulcrum.Client.Configuration(network: .chipnet)
let chipnetClient = try await SwiftFulcrum.Client(
    configuration: configuration
)
```

## Core Capabilities

- Actor-isolated `SwiftFulcrum.Client` entrypoint for unary requests and streaming subscriptions
- Typed endpoints via `SwiftFulcrum.API`
- Typed response models under `SwiftFulcrum.Response.*`
- Automatic protocol negotiation plus reconnect and failover with subscription recovery
- Bundled public server catalogs for `mainnet`, `testnet`, and `chipnet`
- Connection-state streams, diagnostics snapshots, and OpalDiagnostics events for observability

## Diagnostics

SwiftFulcrum emits structured OpalDiagnostics records at high-signal boundaries such as JSON-RPC encoding and decoding, request routing, WebSocket send and receive, reconnect attempts, and subscription recovery. Host applications own runtime diagnostics policy, including minimum level, category filtering, and recent-record buffering.

Targets that configure diagnostics directly should depend on the `OpalDiagnostics` product and import it alongside SwiftFulcrum.

Use `enabledIncludingSubcategories` when the host app wants every SwiftFulcrum diagnostics category under `fulcrum`.

```swift
import OpalDiagnostics

OpalDiagnostics.configure(
    .init(
        minimumLevel: .debug,
        categoryFilter: .enabledIncludingSubcategories(["fulcrum"]),
        bufferPolicy: .enabled(capacity: 500)
    )
)
```

SwiftFulcrum does not print directly and does not expose package-specific logging adapters. Full endpoint URLs, payload previews, server reason strings, localized error messages, addresses, script hashes, transaction IDs, tokens, and JSON-RPC params are treated as private fields.

## Testing

```bash
swift test
```

Set `SWIFTFULCRUM_RUN_NETWORK=1` to enable the opt-in network test suite.
