// Client~JSONRPC.swift

import Foundation

extension Client {
    typealias RegularResponseIdentifier = UUID
    typealias SubscriptionResponseIdentifier = SubscriptionKey
    
    typealias RegularResponseHandler = @Sendable (Result<Data, Fulcrum.Error>) -> Void
    typealias SubscriptionResponseHandler = @Sendable (Result<Data, Fulcrum.Error>) -> Void
}

extension Client {
    struct SubscriptionKey {
        let methodPath: String
        let identifier: String?
        
        var string: String { identifier.map {"\(methodPath):\($0)"} ?? methodPath }
    }
    
    actor SubscriptionToken {
        nonisolated let requestID: UUID
        nonisolated let key: Client.SubscriptionKey
        private let cancelClosure: @Sendable () async -> Void
        private var isCancelled: Bool
        
        init(requestID: UUID,
             key: Client.SubscriptionKey,
             cancelClosure: @escaping @Sendable () async -> Void) {
            self.requestID = requestID
            self.key = key
            self.cancelClosure = cancelClosure
            self.isCancelled = false
        }
        
        func cancel() async {
            guard !isCancelled else { return }
            self.isCancelled = true
            await cancelClosure()
        }
        
        deinit {
            let alreadyCancelled = isCancelled
            guard !alreadyCancelled else { return }
            
            let closure = cancelClosure
            Task {
                await closure()
            }
        }
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

extension Client.SubscriptionKey: Hashable, Sendable {}

extension Client.SubscriptionToken: Hashable, Sendable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(requestID)
        hasher.combine(key)
    }
    
    static func == (lhs: Client.SubscriptionToken, rhs: Client.SubscriptionToken) -> Bool {
        lhs.requestID == rhs.requestID &&
        lhs.key == rhs.key
    }
}
