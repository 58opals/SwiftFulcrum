// Client~ResponseHandler.swift

import Foundation

extension Client {
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
        let failure = Error.transport(.network(error))
        regularResponseHandlers.values.forEach { $0(.failure(failure)) }
        subscriptionResponseHandlers.values.forEach { $0(.failure(failure)) }
        regularResponseHandlers.removeAll()
        subscriptionResponseHandlers.removeAll()
    }
}
