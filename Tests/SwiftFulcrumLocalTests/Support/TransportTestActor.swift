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

    var lifecycleContinuationsBySubscriberIdentifier:
        [UUID: AsyncStream<SwiftFulcrum.Transport.State.Event>.Continuation] = .init()

    var connectionStateBuffer: [SwiftFulcrum.Client.ConnectionState] = .init()
    var connectionStateContinuationsBySubscriberIdentifier:
        [UUID: AsyncStream<SwiftFulcrum.Client.ConnectionState>.Continuation] = .init()
    var shouldPauseNextConnectionStateRead = false
    var pendingConnectionStateReadContinuations: [CheckedContinuation<Void, Never>] = .init()
    var endpointReadsBeforePause: Int?
    var pendingEndpointReadContinuations: [CheckedContinuation<Void, Never>] = .init()

    var outgoingQueue: [URLSessionWebSocketTask.Message] = .init()
    var pendingOutgoingContinuations: [CheckedContinuation<URLSessionWebSocketTask.Message, Never>] = .init()
    var sentMessages: [URLSessionWebSocketTask.Message] = .init()
    var connectDelay: Duration?
    var shouldPauseDisconnect = false
    var pendingDisconnectContinuations: [CheckedContinuation<Void, Never>] = .init()
    var outgoingSendDelay: Duration?
    var shouldPauseOutgoingSend = false
    var pendingOutgoingSendGateContinuations: [CheckedContinuation<Void, Never>] = .init()
    var outgoingSendFailuresByMethodPath: [String: Swift.Error] = .init()

    var reconnectFailure: Swift.Error?
    var reconnectAttempts = 0
    var reconnectSuccessCount = 0
    var reconnectSuccessReadsBeforePause: Int?
    var pendingReconnectSuccessReadContinuations:
        [CheckedContinuation<Void, Never>] = .init()

    init(endpoint: URL = URL(string: "wss://example.invalid")!) {
        self.currentEndpoint = endpoint
    }

    var connectionState: SwiftFulcrum.Client.ConnectionState {
        get async {
            if shouldPauseNextConnectionStateRead {
                shouldPauseNextConnectionStateRead = false
                await withCheckedContinuation { continuation in
                    pendingConnectionStateReadContinuations.append(continuation)
                }
            }
            return connectionStateValue
        }
    }
    var closeInformation: CloseInformation { closeInformationValue }
    var reconnectSuccesses: Int {
        get async {
            if let reconnectSuccessReadsBeforePause {
                if reconnectSuccessReadsBeforePause == 0 {
                    self.reconnectSuccessReadsBeforePause = nil
                    await withCheckedContinuation { continuation in
                        pendingReconnectSuccessReadContinuations.append(
                            continuation
                        )
                    }
                } else {
                    self.reconnectSuccessReadsBeforePause =
                        reconnectSuccessReadsBeforePause - 1
                }
            }
            return reconnectSuccessCount
        }
    }
    var endpoint: URL {
        get async {
            if let endpointReadsBeforePause {
                if endpointReadsBeforePause == 0 {
                    self.endpointReadsBeforePause = nil
                    await withCheckedContinuation { continuation in
                        pendingEndpointReadContinuations.append(continuation)
                    }
                } else {
                    self.endpointReadsBeforePause = endpointReadsBeforePause - 1
                }
            }
            return currentEndpoint
        }
    }
}
