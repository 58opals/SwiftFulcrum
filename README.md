# SwiftFulcrum

SwiftFulcrum is an innovative Swift framework designed to facilitate easy and efficient communication with Fulcrum servers, focusing on integrating Bitcoin Cash functionalities into Swift applications with a type-safe, high-level API.

## Features

- **Type-Safe API**: Leverages Swift's strong type system for safer Bitcoin Cash transactions and queries.
- **Real-Time Updates**: Subscribe to blockchain changes and mempool events with WebSocket support.
- **Concurrency Support**: Utilizes the Combine framework for robust and efficient concurrency management.
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
import Combine
```

#### Initializing the Client

Initialize the client to interact with Fulcrum servers:

```swift
var fulcrum = try SwiftFulcrum()
var cancellables = Set<AnyCancellable>()
```

### Making Requests

SwiftFulcrum supports both *regular requests* and *subscription requests*. The framework leverages Combine for handling asynchronous operations, providing a powerful and flexible concurrency model.

#### Regular Requests

Submit a regular request to retrieve blockchain information:

```swift
Task {
    do {
        let (id, publisher) = try await fulcrum.submit(
            method: .blockchain(.estimateFee(numberOfBlocks: 6)),
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.EstimateFeeJSONRPCResult>.self
        )
        publisher
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("\(id) finished.")
                    case .failure(let error):
                        print("Request failed with error: \(error.localizedDescription)")
                    }
                },
                receiveValue: { estimateFee in
                    print("Estimate fee: \(estimateFee.fee)")
                }
            )
            .store(in: &cancellables)
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
        let (id, publisher) = try await fulcrum.submit(
            method: .blockchain(.address(.subscribe(address: address))),
            resultType: Response.JSONRPCGeneric<Response.Result.Blockchain.Address.SubscribeJSONRPCResult>.self,
            notificationType: Response.JSONRPCGeneric<Response.Result.Blockchain.Address.SubscribeJSONRPCNotification>.self
        )
        publisher
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("\(id) finished.")
                    case .failure(let error):
                        print("Subscription failed with error: \(error.localizedDescription)")
                    }
                },
                receiveValue: { notification in
                    print(notification)
                }
            )
            .store(in: &cancellables)
    } catch {
        print("Failed to submit subscription: \(error.localizedDescription)")
    }
}
```

## Concurrency Support with Combine

SwiftFulcrum leverages the Combine framework to handle concurrency in a declarative manner. This approach provides several benefits:

- **Asynchronous Programming**: Combine allows you to handle asynchronous operations with publishers and subscribers, making it easier to manage complex data flows and state changes.
- **Error Handling**: Combine provides built-in support for handling errors in the data stream, enabling robust and resilient applications.
- **Type Safety**: Combine's use of Swift's strong type system ensures that your asynchronous code is type-safe, reducing runtime errors.
- **Composability**: Combine's operators allow you to compose complex data processing pipelines, making your code more modular and reusable

### Example: Regular Request Flow

1. **Submit the Request**: The `submit` method sends a request and returns a `Future` publisher.
2. **Handle the Response**: The `sink` operator subscribes to the `Future` and handles the response or any errors.

### Example: Subscription Request Flow

1. **Submit the Subscription**: The `submit` method sends a subscription request and returns a `PassthroughSubject`.
2. **Receive Notifications**: The `sink` operator subscribes to the `PassthroughSubject` and processes incoming notifications or any errors.

### Learn More about Combine

For more information on how to use the Combine framework, refer to the [official Apple developer documentation](https://developer.apple.com/documentation/combine).

### Acknowledgments

- Thanks to the [Fulcrum Protocol](https://electrum-cash-protocol.readthedocs.io/) team for providing the specifications.
- Contributors who have helped shape SwiftFulcrum into what it is today.
