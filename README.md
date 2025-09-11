![Swift 6.0](https://img.shields.io/badge/swift-6.2-orange)
![SPM](https://img.shields.io/badge/Package%20Manager-SPM-informational)
![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-blue)

# SwiftFulcrum

SwiftFulcrum is a **pure‑Swift**, type‑safe framework for interacting with Fulcrum servers on the Bitcoin Cash network. Built on modern Swift Concurrency—actors, `async/await`, `AsyncThrowingStream`—it streams live blockchain data with almost zero boiler‑plate.

## Features

| Area | What you get |
| ---- | ------------ |
| **Type‑safe RPC layer** | Exhaustive `Method` enum generates JSON‑RPC at compile‑time. |
| **Structured concurrency** | All shared state lives in actors (`Fulcrum`, `Client`, `WebSocket`) for race‑free access. |
| **Real‑time notifications** | Subscribe to address, transaction, header, and DS‑Proof events via `AsyncThrowingStream`. |
| **Robust error model** | Every issue surfaces as `Fulcrum.Error`; pending requests are finished with `.connectionClosed` when the socket closes. |
| **Safe lifecycle** | Idempotent `start()`/`stop()` and a configurable WebSocket handshake timeout. |
| **Automatic reconnection** | Automatic exponential back‑off and a `Fulcrum.reconnect()` helper for instant server switching. |
| **Swift PM package** | Runs on iOS, macOS, watchOS, tvOS and visionOS. |

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

### Basic Usage

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

#### Reconnect

```swift
try await fulcrum.reconnect()
```

Use ``Fulcrum/reconnect()`` to switch servers or recover after a disconnect.
Reconnection failures bubble up as ``Fulcrum/Error/Transport``.

#### One‑shot Request

```swift
let response: Fulcrum.RPCResponse<
    Response.Result.Blockchain.EstimateFee, Never
> = try await fulcrum.submit(
    method: .blockchain(.estimateFee(numberOfBlocks: 6))
)

if let estimate = response.extractRegularResponse() {
    print("Current fee ≈ \(estimate.fee) BCH")
}
```

#### Streaming Subscription

```swift
let address = "qrsrz5mzve6kyr6ne6lgsvlgxvs3hqm6huxhd8gqwj"

let response: Fulcrum.RPCResponse<
    Response.Result.Blockchain.Address.Subscribe,
    Response.Result.Blockchain.Address.SubscribeNotification
> = try await fulcrum.submit(
    method: .blockchain(.address(.subscribe(address: address)))
)

guard let (initial, updates, cancel) = response.extractSubscriptionStream() else { return }

print("Initial status: \(initial)")

Task {
    for try await update in updates {
        print("Update: \(update)")
    }
}

// …later
await cancel()   // stop the server‑side subscription
```

---

## 🧵 Concurrency Design

```text
┌── Your App
│
│ await fulcrum.submit(…)
│ ← RPCResponse
├─ Fulcrum   (actor) – public API, validation
├─ Client    (actor) – routing, reconnect helper
└─ WebSocket (actor) – URLSessionWebSocketTask + back‑off loop
```

All mutable state is actor‑isolated: **no locks, no data races.**

---

## ⚠️ Error Handling

```swift
do {
    let result = try await fulcrum.submit(…)
} catch let error as Fulcrum.Error {
    switch error {
    case .transport(.connectionClosed(let code, let reason)):
        print("Socket closed: \(code) – \(reason ?? "none")")
    case .rpc(let server):
        print("Server error \(server.code): \(server.message)")
    case .coding(let detail), .client(let detail):
        print("Library error: \(detail)")
    }
}
```

Every RPC either returns a value, throws an encode/ server error, or returns `.connectionClosed`—**no silent time‑outs.**

---

© 2025 Opal Wallet • 58 Opals
