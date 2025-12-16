// Fulcrum+Diagnostics.swift

import Foundation

extension Fulcrum {
    public enum Diagnostics {}
}

extension Fulcrum.Diagnostics {
    public struct Snapshot: Sendable {
        public let reconnectAttempts: Int
        public let reconnectSuccesses: Int
        public let inflightUnaryCallCount: Int
        public let activeSubscriptionCount: Int
        
        public init(
            reconnectAttempts: Int,
            reconnectSuccesses: Int,
            inflightUnaryCallCount: Int,
            activeSubscriptionCount: Int
        ) {
            self.reconnectAttempts = reconnectAttempts
            self.reconnectSuccesses = reconnectSuccesses
            self.inflightUnaryCallCount = inflightUnaryCallCount
            self.activeSubscriptionCount = activeSubscriptionCount
        }
    }
    
    public struct Subscription: Sendable {
        public let methodPath: String
        public let identifier: String?
        
        public init(methodPath: String, identifier: String?) {
            self.methodPath = methodPath
            self.identifier = identifier
        }
    }
    
    struct TransportSnapshot: Sendable {
        let reconnectAttempts: Int
        let reconnectSuccesses: Int
    }
}

extension Fulcrum {
    public func makeDiagnosticsSnapshot() async -> Diagnostics.Snapshot {
        await client.makeDiagnosticsSnapshot()
    }
    
    public func listSubscriptions() async -> [Diagnostics.Subscription] {
        await client.listSubscriptions()
    }
}
