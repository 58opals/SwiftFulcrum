// FulcrumClient+DiagnosticsModel.swift

import Foundation

extension FulcrumClient {
    public enum DiagnosticsModel {}
}

extension FulcrumClient.DiagnosticsModel {
    public struct SnapshotModel: Sendable {
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
    
    public struct SubscriptionModel: Sendable {
        public let methodPath: String
        public let identifier: String?
        
        public init(methodPath: String, identifier: String?) {
            self.methodPath = methodPath
            self.identifier = identifier
        }
    }
    
    struct TransportSnapshotModel: Sendable {
        let reconnectAttempts: Int
        let reconnectSuccesses: Int
    }
}

extension FulcrumClient {
    public func makeDiagnosticsSnapshot() async -> DiagnosticsModel.SnapshotModel {
        await client.makeDiagnosticsSnapshot()
    }
    
    public func listSubscriptions() async -> [DiagnosticsModel.SubscriptionModel] {
        await client.listSubscriptions()
    }
}
