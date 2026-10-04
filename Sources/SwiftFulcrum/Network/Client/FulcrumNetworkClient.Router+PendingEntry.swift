// FulcrumNetworkClient.Router+PendingEntry.swift

import Foundation

extension FulcrumNetworkClient.Router {
    enum PendingEntry {
        case unary(
            AsyncThrowingStream<Data, Swift.Error>.Continuation,
            subscriptionRestore: FulcrumNetworkClient.SubscriptionRestoreContext?
        )
        case stream(
            SubscriptionSink,
            registrationIdentifier: UUID,
            overflowError: Swift.Error?,
            terminationAction: @Sendable (Swift.Error?) async -> Void
        )
    }
}

extension FulcrumNetworkClient.Router {
    enum SubscriptionSink {
        enum YieldResult { case enqueued, dropped, terminated }
        case raw(AsyncThrowingStream<Data, Swift.Error>.Continuation)
        case observed(AsyncThrowingStream<FulcrumNetworkClient.SubscriptionResponse, Swift.Error>.Continuation)

        func yield(_ data: Data, generation: UInt64) -> YieldResult {
            switch self {
            case .raw(let continuation):
                switch continuation.yield(data) {
                case .enqueued: return .enqueued
                case .dropped: return .dropped
                case .terminated: return .terminated
                @unknown default: return .terminated
                }
            case .observed(let continuation):
                switch continuation.yield(.init(data: data, generation: generation)) {
                case .enqueued: return .enqueued
                case .dropped: return .dropped
                case .terminated: return .terminated
                @unknown default: return .terminated
                }
            }
        }
        func finish(throwing error: Swift.Error? = nil) {
            switch self {
            case .raw(let continuation): continuation.finish(throwing: error)
            case .observed(let continuation): continuation.finish(throwing: error)
            }
        }
    }
}
