// TransportTestActor~Queues.swift

import Foundation
@testable import SwiftFulcrum

extension TransportTestActor {
    func enqueueIncoming(_ message: URLSessionWebSocketTask.Message) {
        incomingBuffer.append(.success(message))
        flushIncomingBuffer()
    }

    func enqueueLifecycleEvent(_ event: SwiftFulcrum.Transport.State.Event) {
        lifecycleBuffer.append(event)
        apply(event)
        flushLifecycleBuffer()
    }

    func dequeueOutgoing() async -> URLSessionWebSocketTask.Message {
        if !outgoingQueue.isEmpty {
            return outgoingQueue.removeFirst()
        }
        return await withCheckedContinuation { continuation in
            pendingOutgoingContinuations.append(continuation)
        }
    }

    func flushIncomingBuffer() {
        guard let incomingContinuation else { return }
        for entry in incomingBuffer {
            switch entry {
            case .success(let message):
                incomingContinuation.yield(message)
            case .failure(let error):
                incomingContinuation.finish(throwing: error)
            }
        }
        incomingBuffer.removeAll()
    }

    func flushLifecycleBuffer() {
        guard let lifecycleContinuation else { return }
        for event in lifecycleBuffer {
            lifecycleContinuation.yield(event)
        }
        lifecycleBuffer.removeAll()
    }

    func flushConnectionStateBuffer() {
        guard !connectionStateContinuationsBySubscriberIdentifier.isEmpty else { return }
        for state in connectionStateBuffer {
            for continuation in connectionStateContinuationsBySubscriberIdentifier.values {
                continuation.yield(state)
            }
        }
        connectionStateBuffer.removeAll()
    }
}
