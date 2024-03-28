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
let client = Client(webSocket: WebSocket(url: URL(string: "wss://example.com:50004")!))
try await client.sendRequest(from: Method.blockchain(.getInfo))
```

## Acknowledgments

- Thanks to the [Fulcrum Protocol](https://electrum-cash-protocol.readthedocs.io/) team for providing the specifications.
- Contributors who have helped shape SwiftFulcrum into what it is today.
