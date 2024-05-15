# SwiftFulcrum

SwiftFulcrum is an innovative Swift framework designed to facilitate easy and efficient communication with Fulcrum servers, focusing on integrating Bitcoin Cash functionalities into Swift applications with a type-safe, high-level API.

## Features

- **Type-Safe API**: Leverages Swift's strong type system for safer Bitcoin Cash transactions and queries.
- **Real-Time Updates**: Subscribe to blockchain changes and mempool events with WebSocket support.
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

Import SwiftFulcrum and start interacting with the Fulcrum protocol:

```swift
import SwiftFulcrum
```

Initialize the client and make a request to retrieve blockchain information:

```swift
var fulcrum = try SwiftFulcrum()

await fulcrum.submitRequest(
    .blockchain(.estimateFee(6)),
    resultType: Response.Result.Blockchain.EstimateFee.self
) { result in
    switch result {
    case .success(let estimateFeeResponse):
        print("Estimate fee: \(estimateFeeResponse.fee)")
    case .failure(let error):
        fatalError("Estimate fee failed: \(error.localizedDescription)")
    }
}

await fulcrum.submitRequest(
    .blockchain(.headers(.getTip)),
    resultType: Response.Result.Blockchain.Headers.GetTip.self
) { result in
    switch result {
    case .success(let getTipResponse):
        print("Headers tip height: \(getTipResponse.height)")
    case .failure(let error):
        fatalError("Get headers tip failed: \(error.localizedDescription)")
    }
}

await fulcrum.submitRequest(.blockchain(
    .transaction(.broadcast(sampleRawTransaction))),
    resultType: Response.Result.Blockchain.Transaction.Broadcast.self
) { result in
    switch result {
    case .success(let broadcastResponse):
        print("Broadcast success: \(broadcastResponse.success)")
    case .failure(let error):
        fatalError("Broadcast transaction failed: \(error.localizedDescription)")
    }
}

await fulcrum.submitSubscription(
    .blockchain(.address(.subscribe(sampleAddress))),
    notificationType: Response.Result.Blockchain.Address.SubscribeNotification.self
) { result in
    switch result {
    case .success(let subscribeNotification):
        print(subscribeNotification)
    case .failure(let error):
        fatalError("Address subscription failed: \(error.localizedDescription)")
    }
}
```

## Acknowledgments

- Thanks to the [Fulcrum Protocol](https://electrum-cash-protocol.readthedocs.io/) team for providing the specifications.
- Contributors who have helped shape SwiftFulcrum into what it is today.
