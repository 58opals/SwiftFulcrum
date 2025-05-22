![Swift 6.0](https://img.shields.io/badge/swift-6.0-orange)
![SPM](https://img.shields.io/badge/Package%20Manager-SPM-informational)
![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-blue)

# SwiftFulcrum

SwiftFulcrum is a pure‑Swift framework for **fast, type‑safe** interaction with Fulcrum servers on the Bitcoin Cash network. Built entirely on Swift Concurrency—actors, `async/await`, `AsyncThrowingStream`—it delivers real‑time blockchain data with minimal boilerplate.

## Features

| Area                        | What you get                                                                                                      |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Type‑safe RPC layer**     | Exhaustive `Method` enum generates JSON‑RPC requests at compile time.                                             |
| **Structured concurrency**  | All shared state lives in actors (`Fulcrum`, `Client`, `WebSocket`).                                              |
| **Real‑time notifications** | Subscribe to address, transaction, header, and DS‑Proof events via `AsyncThrowingStream`.                         |
| **Robust error model**      | Every failure surfaces as `Fulcrum.Error`; in-flight requests resume with `.connectionClosed` if the socket dies. |
| **Automatic reconnection**  | Exponential back-off (capped at 120 s) with a single authoritative reconnect loop—no duplicate attempts.          |
| **Swift PM package**        | Works on iOS, macOS, watchOS, tvOS, and visionOS.                                                                 |

---

## Getting Started

### Installation (Swift Package Manager)

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/58opals/SwiftFulcrum.git",
        .upToNextMajor(from: "0.2.0")
    )
]
```

### Basic Usage

#### Connect

```swift
import SwiftFulcrum

let fulcrum = try Fulcrum(url: "wss://fulcrum.example.com:50004")

Task {
    do {
        try await fulcrum.start()
        print("Connected to Fulcrum server.")
        defer { await fulcrum.stop() }
    } catch {
        print("Connection error: \(error.localizedDescription)")
    }
}
```

#### One‑shot Request

```swift
Task {
    // Estimate the fee for confirmation within 6 blocks
    do {
        let (requestID, feeEstimate): (UUID, Response.Result.Blockchain.EstimateFee) = try await fulcrum.submit(
            method: .blockchain(.estimateFee(numberOfBlocks: 6)),
            responseType: Response.Result.Blockchain.EstimateFee.self
        )
        print("Fee estimate for request \(requestID): \(feeEstimate.fee) BCH")
    } catch {
        print("Request failed: \(error.localizedDescription)")
    }
}
```

#### Streaming Subscription

```swift
Task {
    let address = "qrsrz5mzve6kyr6ne6lgsvlgxvs3hqm6huxhd8gqwj"

    do {
        let (requestID, initialResponse, notifications) = try await fulcrum.submit(
            method: .blockchain(.address(.subscribe(address: address))),
            notificationType: Response.Result.Blockchain.Address.SubscribeNotification.self
        )

        print("Initial status for subscription \(requestID): \(initialResponse.status)")

        for try await notification in notifications {
            print("Update for \(notification.subscriptionIdentifier): \(notification.status ?? "<nil>")")
        }
    } catch {
        print("Subscription error: \(error.localizedDescription)")
    }
}
```

---

## Concurrency Design

```text
┌── Your App
│
│  await fulcrum.submit(…)
│  ← result / stream
├─ Fulcrum   (actor) – public API, high-level validation
├─ Client    (actor) – request/response routing, handler tables
└─ WebSocket (actor) – URLSessionWebSocketTask + single reconnect loop
```

All mutable state is actor-isolated, guaranteeing thread safety without locks.

---

## Error Handling

```swift
do {
    try await fulcrum.submit(…)
} catch let error as Fulcrum.Error {
    switch error {
    case .transport(let transportError):
        print("Transport error: \(transportError)")
    case .rpc(let serverError):
        print("Server error: \(serverError)")
    case .coding(let codingError):
        print("Coding error: \(codingError)")
    case .client(let clientError):
        print("Client error: \(clientError)")
    }
}
```

Every RPC either returns a result, throws a decode/server error, or throws `.connectionClosed`—no silent timeouts.

---

© 2025 Opal Wallet / 58 Opals
