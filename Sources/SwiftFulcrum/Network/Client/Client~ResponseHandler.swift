// Client~ResponseHandler.swift

import Foundation

extension Client {
    func insertRegularHandler(for id: RegularResponseIdentifier, handler: @escaping RegularResponseHandler) throws {
        guard regularResponseHandlers[id] == nil else { throw Fulcrum.Error.client(.duplicateHandler) }
        regularResponseHandlers[id] = handler
    }
    
    func insertSubscriptionHandler(for key: SubscriptionResponseIdentifier, handler: @escaping SubscriptionResponseHandler) throws {
        guard subscriptionResponseHandlers[key] == nil else { throw Fulcrum.Error.client(.duplicateHandler) }
        subscriptionResponseHandlers[key] = handler
    }
    
    func removeRegularResponseHandler(for id: RegularResponseIdentifier) {
        regularResponseHandlers.removeValue(forKey: id)
    }
    
    func removeSubscriptionResponseHandler(for key: SubscriptionResponseIdentifier) {
        subscriptionResponseHandlers.removeValue(forKey: key)
    }
    
    func failAllPendingRequests(with error: Fulcrum.Error, includeSubscriptions: Bool = true) {
        regularResponseHandlers.values.forEach { $0(.failure(error)) }
        regularResponseHandlers.removeAll()
        
        guard includeSubscriptions else { return }
        subscriptionResponseHandlers.values.forEach { $0(.failure(error)) }
        subscriptionResponseHandlers.removeAll()
    }
}
