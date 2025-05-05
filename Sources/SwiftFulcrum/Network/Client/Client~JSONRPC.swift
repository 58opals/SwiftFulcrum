// Client~JSONRPC.swift

import Foundation

extension Client {
    typealias RegularResponseIdentifier = UUID
    typealias SubscriptionResponseIdentifier = SubscriptionKey
    
    typealias RegularResponseHandler      = @Sendable (Result<Data, Client.Error>) -> Void
    typealias SubscriptionResponseHandler = @Sendable (Result<Data, Client.Error>) -> Void
}

extension Client {
    struct SubscriptionKey {
        let methodPath: String
        let identifier: String?
        
        var string: String { identifier.map {"\(methodPath):\($0)"} ?? methodPath }
    }
    
    struct SubscriptionToken {
        let requestID: UUID
        let key: Client.SubscriptionKey
        let _cancel: @Sendable () async -> Void
        
        func cancel() async { await _cancel() }
    }
}

extension Client: Hashable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Client, rhs: Client) -> Bool {
        lhs.id == rhs.id
    }
}

extension Client.SubscriptionKey: Hashable {}

extension Client.SubscriptionToken: Hashable, Sendable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(requestID)
        hasher.combine(key)
    }
    
    static func == (lhs: Client.SubscriptionToken, rhs: Client.SubscriptionToken) -> Bool {
        lhs.requestID == rhs.requestID &&
        lhs.key == rhs.key
    }
}
