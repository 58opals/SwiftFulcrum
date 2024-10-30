# SwiftFulcrum

SwiftFulcrum is an innovative Swift framework designed to facilitate easy and efficient communication with Fulcrum servers, focusing on integrating Bitcoin Cash functionalities into Swift applications with a type-safe, high-level API.

## Features

- **Type-Safe API**: Leverages Swift's strong type system for safer Bitcoin Cash transactions and queries.
- **Real-Time Updates**: Subscribe to blockchain changes and mempool events with WebSocket support.
- **Swift Concurrency**: Uses Swift's modern concurrency features like `async/await` and `actor` for efficient and thread-safe operations.
- **Extensible**: Designed with modularity in mind, allowing for easy customization.

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

To start using SwiftFulcrum, import it into your Swift file:

```swift
import SwiftFulcrum
```

#### Initializing the Client

Initialize the client to interact with Fulcrum servers:

```swift
let fulcrum = try Fulcrum(url: "wss://example-fulcrum-server.com:50004")
```

### Making Requests

SwiftFulcrum supports both *regular requests* and *subscription requests*, leveraging Swift's native concurrency (`async/await`) for simplified management of asynchronous operations.

#### Regular Requests

Submit a regular request to retrieve blockchain information:

```swift
Task {
    do {
        let (id, result): (UUID, Response.JSONRPC.Result.Blockchain.EstimateFee) = try await fulcrum.submit(
            method: .blockchain(.estimateFee(numberOfBlocks: 6)),
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.EstimateFee>.self
        )
        print("Request \(id) completed. Estimated fee: \(result)")
    } catch {
        print("Failed to submit request: \(error.localizedDescription)")
    }
}
```

#### Subscription Requests

Submit a subscription request to receive real-time updates:

```swift
Task {
    do {
        let address = "qrsrz5mzve6kyr6ne6lgsvlgxvs3hqm6huxhd8gqwj"
        let (id, initialResponse, notificationStream): (UUID, Response.JSONRPC.Result.Blockchain.Address.SubscribeNotification?, AsyncStream<Response.JSONRPC.Result.Blockchain.Address.SubscribeNotification?>) = try await fulcrum.submit(
            method: .blockchain(.address(.subscribe(address: address))),
            notificationType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.SubscribeNotification>.self
        )

        if let initialResponse {
            print("Initial Response for request \(id): \(initialResponse)")
        }

        for await notification in notificationStream {
            if let notification {
                print("Notification received for request \(id): \(notification)")
            }
        }
    } catch {
        print("Failed to submit subscription: \(error.localizedDescription)")
    }
}
```

## Concurrency with Swift Actors

SwiftFulcrum now uses Swift's native `actor` model for managing concurrency, ensuring that operations are handled in a thread-safe manner.

- **Actors for Thread Safety**: Components like `Fulcrum`, `Client`, and `WebSocket` are implemented as `actors`, which naturally prevent race conditions.
- **Async/Await for Simplicity**: Instead of using Combine, `async/await` is used for handling asynchronous operations, making the code easier to read and maintain.
- **Continuation API**: SwiftFulcrum also leverages `withCheckedThrowingContinuation` to bridge callback-based APIs to the modern async-await pattern.

### Example: Regular Request Flow

1. **Submit the Request**: The `submit` method sends a request and returns a response asynchronously.
2. **Handle the Response**: Use the `await` keyword to process the response directly, simplifying error handling and data flow.

### Example: Subscription Request Flow

1. **Submit the Subscription**: The `submit` method sends a subscription request and returns an initial response alongside an `AsyncStream` for notifications.
2. **Receive Notifications**: Use a `for await` loop to process incoming notifications as they arrive, with the flexibility to handle the initial response as a regular result.

### Learn More about Swift Concurrency

For more information on Swift concurrency, refer to the [official Apple developer documentation](https://developer.apple.com/documentation/swift/concurrency).

### Acknowledgments

- Thanks to the [Fulcrum Protocol](https://electrum-cash-protocol.readthedocs.io/) team for providing the specifications.
