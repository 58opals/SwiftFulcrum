// Client~JSONRPC.swift

import Foundation

extension Client {
    typealias RegularResponseIdentifier = UUID
    typealias SubscriptionResponseIdentifier = SubscriptionKey
    
    typealias RegularResponseHandler = (Result<Data, Fulcrum.Error>) -> Void
    typealias SubscriptionResponseHandler = (Result<Data, Fulcrum.Error>) -> Void
}

extension Client: Hashable {
    struct SubscriptionKey: Hashable {
        let methodPath: String
        let identifier: String?
    }
    
    struct SubscriptionToken: Hashable, Sendable {
        let requestID: UUID
        let key: Client.SubscriptionKey
        let _cancel: @Sendable () async -> Void
        
        func cancel() async { await _cancel() }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(requestID)
            hasher.combine(key)
        }
        
        static func == (lhs: Client.SubscriptionToken, rhs: Client.SubscriptionToken) -> Bool {
            lhs.requestID == rhs.requestID &&
            lhs.key == rhs.key
        }
        
        
    }
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Client, rhs: Client) -> Bool {
        lhs.id == rhs.id
    }
}

extension Client {
    func sendRegularRequest(method: Method,
                            handler: @escaping RegularResponseHandler) async throws -> RegularResponseIdentifier {
        let requestID: UUID  = .init()
        let request: Request = method.createRequest(with: requestID)
        
        try insertRegularHandler(for: requestID, handler: handler)
        
        do {
            try await send(request: request)
        } catch {
            regularResponseHandlers.removeValue(forKey: requestID)
            throw error
        }
        
        return requestID
    }
    
    func sendSubscriptionRequest(method: Method,
                                 initialResponseHandler: @escaping RegularResponseHandler,
                                 notificationHandler: @escaping SubscriptionResponseHandler) async throws -> SubscriptionToken {
        let requestID: UUID    = .init()
        let request: Request   = method.createRequest(with: requestID)
        let subscriptionKey = SubscriptionResponseIdentifier(methodPath: request.method,
                                                             identifier: identifier(for: method))
        
        try insertRegularHandler(for: requestID, handler: initialResponseHandler)
        try insertSubscriptionHandler(for: subscriptionKey, handler: notificationHandler)
        
        do {
            try await send(request: request)
        } catch {
            regularResponseHandlers.removeValue(forKey: requestID)
            subscriptionResponseHandlers.removeValue(forKey: subscriptionKey)
            throw error
        }
        
        let cancelClosure: @Sendable () async -> Void = { [weak self] in
            guard let self else { return }
            await self.removeSubscriptionResponseHandler(for: subscriptionKey)
            // TODO: optionally send an actual "unsubscribe" RPC here.
        }
        
        return .init(requestID: requestID, key: subscriptionKey, _cancel: cancelClosure)
    }
    
    private func sendRequest(from method: Method) async throws -> (uuid: RegularResponseIdentifier,
                                                                   string: SubscriptionResponseIdentifier) {
        let requestIdentifier: UUID = .init()
        let request = method.createRequest(with: requestIdentifier)
        
        let key = SubscriptionKey(methodPath: request.method, identifier: identifier(for: method))
        
        try await self.send(request: request)
        
        return (request.id, key)
    }
    
    func send(request: Request) async throws {
        guard let data = request.data else { throw Error.encodingFailed }
        try await self.send(data: data)
    }
}

extension Client {
    private func addHandler(for identifier: RegularResponseIdentifier, handler: @escaping RegularResponseHandler) {
        regularResponseHandlers[identifier] = handler
    }
    
    private func addHandler(for identifier: SubscriptionResponseIdentifier, handler: @escaping SubscriptionResponseHandler) {
        subscriptionResponseHandlers[identifier] = handler
    }
    
    func insertRegularHandler(for id: RegularResponseIdentifier, handler: @escaping RegularResponseHandler) throws {
        guard regularResponseHandlers[id] == nil else { throw Error.duplicateHandler }
        regularResponseHandlers[id] = handler
    }
    
    func insertSubscriptionHandler(for key: SubscriptionResponseIdentifier, handler: @escaping SubscriptionResponseHandler) throws {
        guard subscriptionResponseHandlers[key] == nil else { throw Error.duplicateHandler }
        subscriptionResponseHandlers[key] = handler
    }
    
    func removeRegularResponseHandler(for id: RegularResponseIdentifier) {
        regularResponseHandlers.removeValue(forKey: id)
    }
    
    func removeSubscriptionResponseHandler(for key: SubscriptionResponseIdentifier) {
        subscriptionResponseHandlers.removeValue(forKey: key)
    }
    
    func failAllPendingRequests(with error: Fulcrum.Error) {
        regularResponseHandlers.values.forEach { $0(.failure(error)) }
        subscriptionResponseHandlers.values.forEach { $0(.failure(error)) }
        regularResponseHandlers.removeAll()
        subscriptionResponseHandlers.removeAll()
    }
}

extension Client {
    func identifier(for method: Method) -> String? {
        switch method {
        case .blockchain(.address(.subscribe(let address))):
            return address
        case .blockchain(.transaction(.subscribe(let txid))):
            return txid
        default:
            return nil
        }
    }
    
    func identifierFromNotification(methodPath: String, data: Data) -> String? {
        switch methodPath {
        case "blockchain.address.subscribe",
            "blockchain.transaction.subscribe":
            struct Envelope: Decodable { let params: [DecodableValue] }
            struct DecodableValue: Decodable { let string: String?
                init(from dec: Decoder) throws {
                    let c = try dec.singleValueContainer()
                    self.string = (try? c.decode(String.self))
                }
            }
            
            if let first = try? JSONDecoder().decode(Envelope.self, from: data).params.first?.string {
                return first
            }
            return nil
        default:
            return nil
        }
    }
}
