// Client+SubscriptionBufferPolicy.swift

import Foundation

extension SwiftFulcrum.Client {
    public enum SubscriptionBufferPolicy: Equatable, Sendable {
        case bounded(capacity: Int)
        case unbounded

        public static let defaultPolicy = Self.bounded(capacity: 256)
    }
}

extension SwiftFulcrum.Client.SubscriptionBufferPolicy {
    func makeBufferingPolicy<Element>() throws -> AsyncThrowingStream<Element, Swift.Error>.Continuation.BufferingPolicy {
        switch self {
        case .bounded(let capacity):
            guard capacity > 0 else {
                throw SwiftFulcrum.Client.Error.client(.invalidSubscriptionBufferCapacity(capacity))
            }
            return .bufferingOldest(capacity)
        case .unbounded:
            return .unbounded
        }
    }

    var overflowError: SwiftFulcrum.Client.Error? {
        guard case .bounded(let capacity) = self else { return nil }
        return .client(.subscriptionUpdateBufferOverflow(capacity))
    }
}
