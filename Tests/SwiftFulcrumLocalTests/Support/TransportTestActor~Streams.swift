// TransportTestActor~Streams.swift

import Foundation
@testable import SwiftFulcrum

extension TransportTestActor {
    func failIncomingStreamForHeartbeatStopTest() {
        incomingContinuation?.finish(
            throwing: SwiftFulcrum.Client.Error.transport(
                .connectionClosed(.goingAway, "Test teardown")
            )
        )
    }

    func makeMessageStream() async -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> {
        if let incomingStream { return incomingStream }
        var continuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Continuation!
        let stream = AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> { innerContinuation in
            continuation = innerContinuation
            innerContinuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.resetIncomingStream() }
            }
        }
        incomingStream = stream
        incomingContinuation = continuation
        flushIncomingBuffer()
        return stream
    }

    func makeLifecycleEvents() async -> AsyncStream<SwiftFulcrum.Transport.State.Event> {
        let subscriberIdentifier = UUID()
        var continuation: AsyncStream<SwiftFulcrum.Transport.State.Event>.Continuation!
        let stream = AsyncStream<SwiftFulcrum.Transport.State.Event> { innerContinuation in
            continuation = innerContinuation
            innerContinuation.onTermination = { @Sendable [weak self] _ in
                Task {
                    await self?.removeLifecycleContinuation(
                        for: subscriberIdentifier
                    )
                }
            }
        }
        lifecycleContinuationsBySubscriberIdentifier[subscriberIdentifier] = continuation
        return stream
    }

    func makeConnectionStateEvents() async -> AsyncStream<SwiftFulcrum.Client.ConnectionState> {
        let subscriberIdentifier = UUID()
        var continuation: AsyncStream<SwiftFulcrum.Client.ConnectionState>.Continuation!
        let stream = AsyncStream<SwiftFulcrum.Client.ConnectionState> { innerContinuation in
            continuation = innerContinuation
            innerContinuation.yield(connectionStateValue)
            innerContinuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.removeConnectionStateContinuation(for: subscriberIdentifier) }
            }
        }
        connectionStateContinuationsBySubscriberIdentifier[subscriberIdentifier] = continuation
        flushConnectionStateBuffer()
        return stream
    }

    func resetIncomingStream() async {
        incomingStream = nil
        incomingContinuation = nil
    }

    func removeConnectionStateContinuation(for subscriberIdentifier: UUID) {
        connectionStateContinuationsBySubscriberIdentifier.removeValue(forKey: subscriberIdentifier)
    }

    func removeLifecycleContinuation(for subscriberIdentifier: UUID) {
        lifecycleContinuationsBySubscriberIdentifier.removeValue(forKey: subscriberIdentifier)
    }
}
