![Swift 6.0](https://img.shields.io/badge/swift-6.0-orange)
![SPM](https://img.shields.io/badge/Package%20Manager-SPM-informational)
![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-blue)

# SwiftFulcrum

SwiftFulcrum is a **pure Swift**, actor-based client for interacting with [Fulcrum](https://github.com/cculianu/Fulcrum) servers on the Bitcoin Cash network. It ships with typed RPC models for the endpoints implemented by this package, resilient WebSocket connectivity, and ergonomics tailored to modern Swift Concurrency.

## Features

- **Typed RPC coverage (for supported endpoints).** Methods are represented by the `Method` enum and decoded into strongly typed `Response.Result` models, including CashTokens helpers and DSProof endpoints.
- **Automatic bootstrap, failover, and resubscription.** Pass an explicit WebSocket URL, or let SwiftFulcrum pick from the bundled mainnet/testnet server lists. Reconnects use exponential back-off with jitter, and stored subscriptions are re-issued after reconnect.
- **Actor-isolated concurrency.** `Fulcrum`, `Client`, and `WebSocket` are actors that encapsulate state, request routing, and stream lifecycles.
- **First-class observability.** Plug in custom `Log.Handler` implementations and `MetricsCollectable` collectors to track lifecycle, send/receive, pings, diagnostics snapshots, and the subscription registry.
- **Connection state + diagnostics.** Consume an `AsyncStream` of `Fulcrum.ConnectionState`, and query `makeDiagnosticsSnapshot()` / `listSubscriptions()`.

---

## Requirements

- Swift 6.0 or newer
- iOS 18, macOS 15, watchOS 11, tvOS 18, or visionOS 2 and later (per package manifest)

## Installation (Swift Package Manager)

Add SwiftFulcrum to your `Package.swift` dependencies:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/58opals/SwiftFulcrum.git", .upToNextMajor(from: "0.4.0"))
]
```

## Quick Start

### Connect + unary call

> Note: `submit(...)` will start/reconnect as needed, but calling `start()` gives you explicit control over connection timing.

```swift
import SwiftFulcrum

Task {
    do {
        // Optional: pass a specific server
        // let fulcrum = try await Fulcrum(url: "wss://your-fulcrum.example")
        let fulcrum = try await Fulcrum()

        try await fulcrum.start()

        let response = try await fulcrum.submit(
            method: .blockchain(.headers(.getTip)),
            responseType: Response.Result.Blockchain.Headers.GetTip.self
        )

        guard let tip = response.extractRegularResponse() else { return }
        print("Best header height: \(tip.height)")

        await fulcrum.stop()
    } catch {
        print("Connection error: \(error)")
    }
}
```

### Subscription (streaming updates)

Subscriptions use the overloaded `submit(...)` that returns `RPCResponse.stream`, which includes:

* the initial response,
* an `AsyncThrowingStream` of notifications,
* and a `cancel` closure.

```swift
import SwiftFulcrum

Task {
    do {
        let fulcrum = try await Fulcrum()
        try await fulcrum.start()

        let response = try await fulcrum.submit(
            method: .blockchain(.headers(.subscribe)),
            initialType: Response.Result.Blockchain.Headers.Subscribe.self,
            notificationType: Response.Result.Blockchain.Headers.SubscribeNotification.self
        )

        guard let (initial, updates, cancel) = response.extractSubscriptionStream() else { return }
        print("Initial best height: \(initial.height)")

        let updatesTask = Task {
            for try await update in updates {
                for block in update.blocks {
                    print("New header: \(block.height)")
                }
            }
        }

        // ... later ...
        await cancel()
        updatesTask.cancel()
        await fulcrum.stop()
    } catch {
        print("Subscription error: \(error)")
    }
}
```

### Connection state

```swift
let stream = await fulcrum.makeConnectionStateStream()
Task {
    for await state in stream {
        print("Fulcrum state: \(state)")
    }
}
```

### Diagnostics

```swift
let snapshot = await fulcrum.makeDiagnosticsSnapshot()
print("Inflight unary calls: \(snapshot.inflightUnaryCallCount)")
print("Active subscriptions: \(snapshot.activeSubscriptionCount)")

let subscriptions = await fulcrum.listSubscriptions()
print("Subscriptions: \(subscriptions)")
```

## Error Handling

All failures funnel through `Fulcrum.Error` with transport, RPC, coding, and client-specific cases.

```swift
do {
    let response = try await fulcrum.submit(
        method: .mempool(.getFeeHistogram),
        responseType: Response.Result.Mempool.GetFeeHistogram.self
    )

    guard let histogram = response.extractRegularResponse() else { return }
    print(histogram)
} catch let error as Fulcrum.Error {
    switch error {
    case .transport(.connectionClosed(let code, let reason)):
        print("Socket closed: \(code) - \(reason ?? "none")")
    case .transport(.heartbeatTimeout):
        print("RPC heartbeat timed out")
    case .rpc(let server):
        print("Server error \(server.code): \(server.message)")
    case .coding, .client:
        print("Library error: \(error)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

---

SwiftFulcrum is crafted by © 2025 Opal Wallet • 58 Opals.
