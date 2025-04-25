import Foundation

extension Client {
    typealias RegularResponseIdentifier = UUID
    typealias SubscriptionResponseIdentifier = String
    
    typealias RegularResponseHandler = (Result<Data, Fulcrum.Error>) -> Void
    typealias SubscriptionResponseHandler = (Result<Data, Fulcrum.Error>) -> Void
}

extension Client {
    func sendRequest(from method: Method) async throws -> (uuid: RegularResponseIdentifier,
                                                           string: SubscriptionResponseIdentifier) {
        let requestIdentifier: UUID = .init()
        let request = method.createRequest(with: requestIdentifier)
        
        try await self.sendRequest(request)
        
        return (request.id, request.method)
    }
    
    func sendRequest(_ request: Request) async throws {
        guard let data = request.data else { throw Error.encodingFailed }
        try await self.send(data: data)
    }
}

extension Client {
    func addHandler(for identifier: RegularResponseIdentifier, handler: @escaping RegularResponseHandler) {
        regularResponseHandlers[identifier] = handler
    }
    
    func addHandler(for identifier: SubscriptionResponseIdentifier, handler: @escaping SubscriptionResponseHandler) {
        subscriptionResponseHandlers[identifier] = handler
    }
    
    func removeRegularResponseHandler(for id: RegularResponseIdentifier) {
        regularResponseHandlers.removeValue(forKey: id)
    }
    
    func removeSubscriptionResponseHandler(for method: SubscriptionResponseIdentifier) {
        subscriptionResponseHandlers.removeValue(forKey: method)
    }
    
    func failAllPendingRequests(with error: Fulcrum.Error) {
        regularResponseHandlers.values.forEach { $0(.failure(error)) }
        subscriptionResponseHandlers.values.forEach { $0(.failure(error)) }
        regularResponseHandlers.removeAll()
        subscriptionResponseHandlers.removeAll()
    }
}
