![Swift 6.0](https://img.shields.io/badge/swift-6.0-orange)
![SPM](https://img.shields.io/badge/Package%20Manager-SPM-informational)
![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-blue)

# SwiftFulcrum

SwiftFulcrum is a **pure Swift**, actor-based client for interacting with [Fulcrum](https://github.com/cculianu/Fulcrum) WebSocket JSON-RPC servers on the Bitcoin Cash network.

It ships with a strongly-typed RPC surface (`Method` + `Response.Result.*` models), **automatic protocol negotiation** via `server.version`, resilient WebSocket connectivity (failover + reconnect + heartbeat), and ergonomics tailored to modern Swift Concurrency.

## Features

- **Typed RPC coverage (for supported endpoints).** Methods are represented by the `Method` enum and decoded into strongly typed `Response.Result` models. Coverage includes `server.*`, `blockchain.*`, and `mempool.*` methods implemented by this package, including CashTokens token filtering and DSProof endpoints.
- **Automatic protocol negotiation (`server.version`).** Connections negotiate a compatible Fulcrum protocol version (default range `1.4` ... `1.6.0`) and opportunistically fetch `server.features` to learn server capabilities.
- **Automatic bootstrap, failover, and resubscription.** Pass an explicit WebSocket URL, or let SwiftFulcrum select from the bundled mainnet/testnet server catalogs. Reconnects use exponential backoff with jitter, and stored subscriptions are re-issued after reconnect.
- **RPC heartbeat.** After connecting, SwiftFulcrum periodically issues `server.ping` (defaults: 25 s interval, 10 s timeout) to detect stalled connections and trigger a reconnect.
- **Actor-isolated concurrency.** `Fulcrum`, `Client`, and `WebSocket` are actors that encapsulate state, request routing, and stream lifecycles.
- **First-class observability.** Plug in custom `Log.Handler` implementations and `MetricsCollectable` collectors to observe connect/disconnect, send/receive, pings, diagnostics snapshots, and subscription registry changes.
- **Connection state + diagnostics.** Consume an `AsyncStream<Fulcrum.ConnectionState>`, query `makeDiagnosticsSnapshot()`, and inspect `listSubscriptions()`.
- **Configurable server catalogs.** Use the bundled catalogs, inject your own `FulcrumServerCatalogLoader`, or supply a bootstrap fallback list.
- **Opt-in quiet logging for scoped work.** Use `Log.perform(withBehavior: .quiet) { ... }` to suppress normal logs for noisy operations.

---

## Supported RPC methods (implemented by this package)

This is the currently supported surface area exposed by `Method` (grouped by namespace):

### `server.*`

- `server.ping`
- `server.version`
- `server.features`

### `blockchain.*`

- Fees
  - `blockchain.estimatefee`
  - `blockchain.relayfee`

- Script hash
  - `blockchain.scripthash.get_balance` (optional CashTokens filtering)
  - `blockchain.scripthash.get_first_use`
  - `blockchain.scripthash.get_history` (supports height-range parameters and `includeUnconfirmed`)
  - `blockchain.scripthash.get_mempool`
  - `blockchain.scripthash.listunspent` (optional CashTokens filtering)
  - `blockchain.scripthash.subscribe` / `blockchain.scripthash.unsubscribe`

- Address
  - `blockchain.address.get_balance` (optional CashTokens filtering)
  - `blockchain.address.get_first_use`
  - `blockchain.address.get_history` (supports height-range parameters and `includeUnconfirmed`)
  - `blockchain.address.get_mempool`
  - `blockchain.address.get_scripthash`
  - `blockchain.address.listunspent` (optional CashTokens filtering)
  - `blockchain.address.subscribe` / `blockchain.address.unsubscribe`

- Headers / blocks
  - `blockchain.headers.get_tip`
  - `blockchain.headers.subscribe` / `blockchain.headers.unsubscribe`
  - `blockchain.block.header`
  - `blockchain.block.headers`
  - `blockchain.header.get`

- Transactions
  - `blockchain.transaction.broadcast`
  - `blockchain.transaction.get`
  - `blockchain.transaction.get_confirmed_blockhash`
  - `blockchain.transaction.get_height`
  - `blockchain.transaction.get_merkle`
  - `blockchain.transaction.id_from_pos`
  - `blockchain.transaction.subscribe` / `blockchain.transaction.unsubscribe`

- DSProof
  - `blockchain.transaction.dsproof.get`
  - `blockchain.transaction.dsproof.list`
  - `blockchain.transaction.dsproof.subscribe` / `blockchain.transaction.dsproof.unsubscribe`

- UTXO
  - `blockchain.utxo.get_info`

### `mempool.*`

- `mempool.get_info`
- `mempool.get_fee_histogram`

---

## Requirements

- Swift 6.0 or newer
- iOS 18, macOS 15, watchOS 11, tvOS 18, or visionOS 2 and later (per package manifest)

## Installation (Swift Package Manager)

Add SwiftFulcrum to your `Package.swift` dependencies.

### Stable (recommended)

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/58opals/SwiftFulcrum.git", .upToNextMajor(from: "0.5.0"))
]
```

### Development (branch)

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/58opals/SwiftFulcrum.git", branch: "develop")
]
```

---

## Quick Start

### Connect + unary call

> Note: `submit(...)` will start/reconnect as needed, but calling `start()` gives you explicit control over connection timing.

```swift
import SwiftFulcrum

Task {
    do {
        // Optional: pass a specific server endpoint
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

`subscribe(...)` returns the initial payload, an `AsyncThrowingStream` of notifications, and a `cancel` closure.

To stop cleanly, **terminate the consumer task** (ending iteration) and then call `cancel()` if you also want to propagate a shared cancellation signal.

```swift
import SwiftFulcrum

Task {
    do {
        let fulcrum = try await Fulcrum()
        try await fulcrum.start()

        let (initial, updates, cancel) = try await fulcrum.subscribe(
            method: .blockchain(.headers(.subscribe)),
            initialType: Response.Result.Blockchain.Headers.Subscribe.self,
            notificationType: Response.Result.Blockchain.Headers.SubscribeNotification.self
        )

        print("Initial best height: \(initial.height)")

        let updatesTask = Task {
            for try await update in updates {
                for block in update.blocks {
                    print("New header: \(block.height)")
                }
            }
        }

        // ... later ...
        updatesTask.cancel()
        await cancel()
        await fulcrum.stop()
    } catch {
        print("Subscription error: \(error)")
    }
}
```

### Query server features (optional)

```swift
let response = try await fulcrum.submit(
    method: .server(.features),
    responseType: Response.Result.Server.Features.self
)

guard let features = response.extractRegularResponse() else { return }
print("CashTokens supported: \(features.hasCashTokens ?? false)")
print("DSProof supported: \(features.hasDoubleSpendProofs ?? false)")
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
print("Reconnect attempts: \(snapshot.reconnectAttempts)")
print("Reconnect successes: \(snapshot.reconnectSuccesses)")
print("Inflight unary calls: \(snapshot.inflightUnaryCallCount)")
print("Active subscriptions: \(snapshot.activeSubscriptionCount)")

let subscriptions = await fulcrum.listSubscriptions()
print("Subscriptions: \(subscriptions)")
```

### Manual reconnect (force failover / refresh)

If you want to proactively cycle to another server (or recover from a bad endpoint), call:

```swift
try await fulcrum.reconnect()
```

---

## Configuration and server selection

Pass a `Fulcrum.Configuration` when you want to customise networking behaviour. You can tune TLS, reconnection policy, protocol negotiation, metrics/logging hooks, maximum message size, URLSession usage, and server sourcing.

```swift
import SwiftFulcrum

let loader = FulcrumServerCatalogLoader.makeConstant([
    URL(string: "wss://my.fulcrum.example")!,
    URL(string: "wss://backup.fulcrum.example")!
])

let configuration = Fulcrum.Configuration(
    reconnect: .init(
        // <= 0 means "unlimited" (the reconnector will still rotate servers)
        maximumReconnectionAttempts: 5,
        reconnectionDelay: 1.5,
        maximumDelay: 30,
        jitterRange: 0.9 ... 1.2
    ),

    // Optional observability hooks
    metrics: MyMetricsCollector(),

    // Logging:
    // - If omitted, SwiftFulcrum logs to the console by default.
    // - Set isLoggingEnabled=false to silence all logs.
    logger: MyLogHandler(),
    isLoggingEnabled: true,

    // Used as a fallback if the bundled catalog is unavailable/empty.
    // Bootstrap URLs are sanitized to ws/wss schemes by the bundled loader.
    bootstrapServers: [URL(string: "wss://fallback.fulcrum.example")!],

    serverCatalogLoader: loader,
    network: .testnet,

    // Optional: override the protocol negotiation range / client name.
    protocolNegotiation: .init(
        clientName: "MyApp/1.0",
        min: ProtocolVersion(string: "1.4")!,
        max: ProtocolVersion(string: "1.6.0")!
    )
)

let fulcrum = try await Fulcrum(configuration: configuration)
```

Notes:

* `FulcrumServerCatalogLoader.bundled` loads from the package’s bundled JSON catalogs (`servers.mainnet.json` / `servers.testnet.json`).
* `FulcrumServerCatalogLoader.makeConstant(...)` expects you to provide valid `ws://` or `wss://` URLs.
* SwiftFulcrum throws `Fulcrum.Error.transport(.setupFailed)` when it cannot resolve any valid servers.

## Timeouts and cancellation

Use `Fulcrum.Call.Options` to control per-call behaviour. A `timeout` bounds the RPC operation (including waiting for a server response). A `Cancellation` can be shared across tasks to cancel unary calls or long-lived subscriptions.

```swift
let cancellation = Fulcrum.Call.Cancellation()

let response = try await fulcrum.submit(
    method: .mempool(.getFeeHistogram),
    responseType: Response.Result.Mempool.GetFeeHistogram.self,
    options: .init(timeout: .seconds(10), cancellation: cancellation)
)

// ... later in your workflow ...
await cancellation.cancel()
```

`submit(...)` will throw `Fulcrum.Error.client(.timeout(...))` if the timeout elapses.

## Error Handling

All failures funnel through `Fulcrum.Error` with transport, RPC, coding, and client-specific cases.

```swift
do {
    let response = try await fulcrum.submit(
        method: .mempool(.getInfo),
        responseType: Response.Result.Mempool.GetInfo.self
    )

    guard let info = response.extractRegularResponse() else { return }
    print(info)
} catch let error as Fulcrum.Error {
    switch error {
    case .transport(.setupFailed):
        print("Could not resolve any valid Fulcrum servers")
    case .transport(.connectionClosed(let code, let reason)):
        print("Socket closed: \(code) - \(reason ?? "none")")
    case .transport(.heartbeatTimeout):
        print("RPC heartbeat timed out")
    case .transport(.network(let networkError)):
        print("Network error: \(networkError)")
    case .client(.timeout(let limit)):
        print("Timed out after \(limit)")
    case .rpc(let server):
        print("Server error \(server.code): \(server.message)")
    case .coding, .client, .transport:
        print("Library error: \(error)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

---

SwiftFulcrum is crafted by © 2026 Opal Wallet • 58 Opals.
