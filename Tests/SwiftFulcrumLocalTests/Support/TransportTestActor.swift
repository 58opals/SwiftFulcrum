// TransportTestActor.swift

import Foundation
@testable import SwiftFulcrum

actor TransportTestActor: TransportAdapter {
    var connectionStateValue: SwiftFulcrum.Client.ConnectionState = .idle
    var closeInformationValue: CloseInformation = (.invalid, nil)
    var currentEndpoint: URL

    var incomingBuffer: [Result<URLSessionWebSocketTask.Message, Swift.Error>] = .init()
    var incomingStream: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>?
    var incomingContinuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Continuation?

    var lifecycleBuffer: [SwiftFulcrum.Transport.State.Event] = .init()
    var lifecycleStream: AsyncStream<SwiftFulcrum.Transport.State.Event>?
    var lifecycleContinuation: AsyncStream<SwiftFulcrum.Transport.State.Event>.Continuation?

    var connectionStateBuffer: [SwiftFulcrum.Client.ConnectionState] = .init()
    var connectionStateContinuationsBySubscriberIdentifier:
        [UUID: AsyncStream<SwiftFulcrum.Client.ConnectionState>.Continuation] = .init()

    var outgoingQueue: [URLSessionWebSocketTask.Message] = .init()
    var pendingOutgoingContinuations: [CheckedContinuation<URLSessionWebSocketTask.Message, Never>] = .init()
    var sentMessages: [URLSessionWebSocketTask.Message] = .init()
    var connectDelay: Duration?
    var outgoingSendDelay: Duration?
    var shouldPauseOutgoingSend = false
    var pendingOutgoingSendGateContinuations: [CheckedContinuation<Void, Never>] = .init()
    var outgoingSendFailuresByMethodPath: [String: Swift.Error] = .init()

    var reconnectFailure: Swift.Error?
    var reconnectAttempts = 0
    var reconnectSuccesses = 0

    init(endpoint: URL = URL(string: "wss://example.invalid")!) {
        self.currentEndpoint = endpoint
    }

    var connectionState: SwiftFulcrum.Client.ConnectionState { connectionStateValue }
    var closeInformation: CloseInformation { closeInformationValue }
    var endpoint: URL { currentEndpoint }
}
