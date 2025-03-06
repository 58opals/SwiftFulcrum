# SwiftFulcrum

SwiftFulcrum is a modern Swift framework that enables efficient and thread-safe communication with Fulcrum servers, specifically designed for integrating Bitcoin Cash capabilities into Swift-based applications. It leverages the latest Swift concurrency features, providing a robust and type-safe API.

## Features

- **Type-Safe API**: Ensures reliable interactions through Swift's powerful type safety.
- **Real-Time Notifications**: Provides seamless subscriptions to blockchain changes, mempool activities, transaction updates, and DS proofs using WebSockets.
- **Swift Actors for Thread Safety**: Utilizes Swift actors (`Fulcrum`, `Client`, `WebSocket`) for safe concurrent operations without data races.
- **Async/Await Integration**: Makes asynchronous operations intuitive, eliminating the complexity of callback-based APIs.
- **Error Handling**: Provides comprehensive error types for robust handling of various response scenarios.
- **Extensible Architecture**: Easily customizable and extendable for specific application requirements.

## Getting Started

### Installation

#### Swift Package Manager

Add SwiftFulcrum as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/58opals/SwiftFulcrum.git", .upToNextMajor(from: "0.1.0"))
]
```

### Usage

#### Importing SwiftFulcrum

```swift
import SwiftFulcrum
```

#### Initializing the Client

```swift
let fulcrum = try Fulcrum(url: "wss://example-fulcrum-server.com:50004")
```

#### Connecting to Fulcrum

Ensure the WebSocket connection is active before sending requests:

```swift
Task {
    do {
        try await fulcrum.start()
        print("Connected to Fulcrum server.")
    } catch {
        print("Connection error: \(error.localizedDescription)")
    }
}
```

#### Regular Requests

Make a standard request to estimate the Bitcoin Cash transaction fee:

```swift
Task {
    do {
        let (requestID, feeEstimate): (UUID, Response.JSONRPC.Result.Blockchain.EstimateFee) = try await fulcrum.submit(
            method: .blockchain(.estimateFee(numberOfBlocks: 6)),
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.EstimateFee>.self
        )
        print("Fee estimate for request \(requestID): \(feeEstimate) BCH")
    } catch {
        print("Request failed: \(error.localizedDescription)")
    }
}
```

#### Subscription Requests

Receive real-time blockchain updates:

```swift
Task {
    let address = "qrsrz5mzve6kyr6ne6lgsvlgxvs3hqm6huxhd8gqwj"
    do {
        let (requestID, initialResponse, notifications): (UUID, Response.JSONRPC.Result.Blockchain.Address.SubscribeNotification?, AsyncStream<Response.JSONRPC.Result.Blockchain.Address.SubscribeNotification?>) = try await fulcrum.submit(
            method: .blockchain(.address(.subscribe(address: address))),
            notificationType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.SubscribeNotification>.self
        )
        
        if let initialResponse {
            print("Initial response for subscription \(requestID): \(String(describing: initialResponse))")
        }

        for await notification in notifications {
            if let notification {
                print("Notification received for request \(requestID): \(notification)")
            }
        }
    } catch {
        print("Subscription error: \(error.localizedDescription)")
    }
}
```

## Swift Actors and Concurrency

SwiftFulcrum utilizes Swift’s `actor` model extensively to handle concurrency:

- **Client Actor**: Manages WebSocket communication, message processing, and response handling securely.
- **Automatic Reconnection**: The internal reconnection logic ensures reliable and resilient WebSocket communication.

### Learn More

Refer to [Apple’s official documentation](https://developer.apple.com/documentation/swift/concurrency) for additional information on Swift concurrency.

## Acknowledgments

- Thanks to the [Fulcrum Protocol](https://electrum-cash-protocol.readthedocs.io/) team for providing detailed protocol specifications.
