import Foundation

extension Client {
    typealias RegularResponseIdentifier = UUID
    typealias SubscriptionResponseIdentifier = String
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
        if let data = request.data {
            try await self.send(data: data)
        } else {
            throw Error.encodingFailed
        }
    }
}

extension Client {
    func addHandler(for identifier: RegularResponseIdentifier, handler: @escaping (Data) throws -> Void) {
        regularResponseHandlers[identifier] = handler
    }
    
    func addHandler(for identifier: SubscriptionResponseIdentifier, handler: @escaping (Data) throws -> Void) {
        subscriptionResponseHandlers[identifier] = handler
    }
    
    func removeRegularResponseHandler(for id: RegularResponseIdentifier) {
        regularResponseHandlers.removeValue(forKey: id)
    }
    
    func removeSubscriptionResponseHandler(for method: SubscriptionResponseIdentifier) {
        subscriptionResponseHandlers.removeValue(forKey: method)
    }
}
