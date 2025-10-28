![Swift 6.0](https://img.shields.io/badge/swift-6.0-orange)
![SPM](https://img.shields.io/badge/Package%20Manager-SPM-informational)
![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-blue)

# SwiftFulcrum

SwiftFulcrum is a **pure-Swift**, type-safe framework for interacting with Fulcrum servers on the Bitcoin Cash network. Built on modern Swift Concurrency-actors, `async/await`, `AsyncThrowingStream`, it streams live blockchain data with almost zero boiler-plate.

## Features

- **Type-safe RPC surface.** Every Fulcrum method is modelled by the ``Method`` enum and strongly typed ``Response.Result`` structures so you get compile-time checking and autocompletion for parameters and payloads.
- **Automatic server bootstrap.** Provide a WebSocket URL or let SwiftFulcrum choose from the curated bootstrap catalog (`Network/WebSocket/servers.json`) with optional custom fallbacks.
- **Actor-isolated concurrency.** ``Fulcrum``, ``Client``, and ``WebSocket`` actors encapsulate state, replays, and reconnection for race-free access.
- **Resilient streaming.** Subscriptions surface as `AsyncThrowingStream` values, automatically resubscribe after reconnects, and expose a cancellation closure.
- **Configurable reconnection.** Tune exponential back-off, jitter, and handshake timeouts through ``Fulcrum.Configuration`` and ``WebSocket.Reconnector.Configuration``.
- **First-class observability.** Plug in custom ``Log.Handler`` instances and ``MetricsCollectable`` implementations to track connections, payload flow, and pings.
- **Robust error model.** Every failure reports through ``Fulcrum.Error`` with precise transport, RPC, coding, and client cases, pending requests complete as soon as the socket closes.

---

## 🚀 Getting Started

### Installation (Swift Package Manager)

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/58opals/SwiftFulcrum.git",
        .upToNextMajor(from: "0.4.0")
    )
]
```

### Quick Start

#### Connect

```swift
import SwiftFulcrum

Task {
    do {
        let fulcrum = try await Fulcrum(url: "wss://fulcrum.example.com:50004")
        try await fulcrum.start()
        print("Connected to Fulcrum server.")
        defer { await fulcrum.stop() }
    } catch {
        print("Connection error: \(error.localizedDescription)")
    }
}
```

Pass `nil` for the `url:` parameter to let SwiftFulcrum select a server from the bundled bootstrap list or your custom
``Fulcrum.Configuration.bootstrapServers``.

#### Reconnect

```swift
try await fulcrum.reconnect()
```

Use ``Fulcrum/reconnect()`` to switch servers or recover after a disconnect.
Reconnection failures bubble up as ``Fulcrum/Error/Transport``.

`Fulcrum` handles exponential back-off and resubscribes active streams after a reconnect completes.

#### One-shot Request

```swift
let response = try await fulcrum.submit(
    method: .blockchain(.headers(.getTip)),
    responseType: Response.Result.Blockchain.Headers.GetTip.self
)

let tip = response.extractRegularResponse()
```

Use ``Fulcrum/RPCResponse/extractRegularResponse()`` to read the single value. Handle the optional return to detect protocol
mismatches or closed sockets.

Use ``RPCResponse/extractRegularResponse()`` to read the single-value result. Handle the optional return to process server responses or gracefully recover when the socket closes.

#### Streaming Subscription

```swift
let response = try await fulcrum.submit(
    method: .blockchain(.headers(.subscribe)),
    initialType: Response.Result.Blockchain.Headers.Subscribe.self,
    notificationType: Response.Result.Blockchain.Headers.SubscribeNotification.self
)

let subscription = response.extractSubscriptionStream()
```

`extractSubscriptionStream()` returns the initial payload, an `AsyncThrowingStream` of notifications, and a cancellation closure.
`guard let (initial, updates, cancel) = subscription else { return }` to iterate updates and tear down the stream when finished.

---

## ⏱️ Request Options, Timeouts, and Cancellation

Every `submit` call accepts `Client.Call.Options` so you can set per-request timeouts or hook up a cancellation token:

```swift
var options = Client.Call.Options(timeout: .seconds(5))
let token = Client.Call.Token()
options.token = token

Task.detached {
    try await Task.sleep(for: .seconds(2))
    await token.cancel()
}

let block = try await fulcrum.submit(
    method: .blockchain(.block(.header(height: 820_000))),
    responseType: Response.Result.Blockchain.Block.Header.self,
    options: options
)
```

When the timeout elapses or the token cancels, SwiftFulcrum completes the request with `Fulcrum.Error.client(.timeout)` or
`.cancelled` and removes any pending handlers from the router.

---

## ⚠️ Error Handling

```swift
do {
    let result = try await fulcrum.submit(…)
} catch let error as Fulcrum.Error {
    switch error {
    case .transport(.connectionClosed(let code, let reason)):
        print("Socket closed: \(code) - \(reason ?? "none")")
    case .rpc(let server):
        print("Server error \(server.code): \(server.message)")
    case .coding(let detail), .client(let detail):
        print("Library error: \(detail)")
    }
}
```

Every RPC either returns a value, throws an encode/server error, or returns `.connectionClosed`, **no silent time-outs.**

---

© 2025 Opal Wallet • 58 Opals
