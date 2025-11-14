![Swift 6.0](https://img.shields.io/badge/swift-6.0-orange)
![SPM](https://img.shields.io/badge/Package%20Manager-SPM-informational)
![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-blue)

# SwiftFulcrum

SwiftFulcrum is a **pure Swift**, actor-based client for interacting with [Fulcrum](https://github.com/cculianu/Fulcrum) servers on the Bitcoin Cash network. It ships with a complete RPC surface, resilient WebSocket connectivity, and ergonomic types tailored to modern Swift Concurrency.

## Features

- **Typed RPC coverage.** Every Fulcrum method is represented by ``Method`` enums and strongly typed ``Response.Result`` models, including CashTokens helpers and DSProof endpoints.
- **Automatic bootstrap & failover.** Pass an explicit WebSocket URL or allow SwiftFulcrum to choose from the bundled mainnet/testnet catalogs with back-off, jitter, and heartbeat-driven reconnection handled for you.
- **Actor-isolated concurrency.** ``Fulcrum``, ``Client``, and ``WebSocket`` are actors that encapsulate state, request routing, and stream resubscription after reconnects.
- **First-class observability.** Plug in custom ``Log.Handler`` implementations and ``MetricsCollectable`` collectors to trace connection lifecycle, messages, and pings.
- **Configurable networking.** Tune TLS, URLSession usage, message size limits, reconnection policy, network selection, and bootstrap overrides through ``Fulcrum.Configuration``.

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

### Connect

```swift
import SwiftFulcrum

Task {
    do {
        let fulcrum = try await Fulcrum()
        try await fulcrum.start()
        
        if let tip = try await fulcrum.submit(
            method: .blockchain(.headers(.getTip)),
            responseType: Response.Result.Blockchain.Headers.GetTip.self).extractRegularResponse() {
                print("Best header height: \(tip.height)")
            }
    
        await fulcrum.stop()
    } catch {
        print("Connection error: \(error.localizedDescription)")
    }
}
```

## Error Handling

All failures funnel through `Fulcrum.Error` with transport, RPC, coding, and client-specific cases. This keeps retries, UI messaging, and analytics easy to reason about.

```swift
do {
    let result = try await fulcrum.submit(method: .mempool(.getFeeHistogram),
                                          responseType: Response.Result.Mempool.GetFeeHistogram.self)
    guard let histogram = result.extractRegularResponse() else { return }
    print(histogram)
} catch let error as Fulcrum.Error {
    switch error {
    case .transport(.connectionClosed(let code, let reason)):
        print("Socket closed: \(code) - \(reason ?? "none")")
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
