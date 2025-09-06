// Client~Subscription.swift

import Foundation

extension Client {
    func makeUnsubscribeMethod(for key: SubscriptionKey) -> Method? {
        let methodPath = key.methodPath
        guard let identifier = key.identifier else { return nil }
        
        switch methodPath {
        case "blockchain.address.subscribe":
            return .blockchain(.address(.unsubscribe(address: identifier)))
        case "blockchain.headers.subscribe":
            return .blockchain(.headers(.unsubscribe))
        case "blockchain.transaction.subscribe":
            return .blockchain(.transaction(.unsubscribe(transactionHash: identifier)))
        case "blockchain.transaction.dsproof.subscribe":
            return .blockchain(.transaction(.dsProof(.unsubscribe(transactionHash: identifier))))
        default:
            return nil
        }
    }
}

extension Client {
    func resubscribeStoredMethods() async {
        for method in subscriptionMethods.values {
            let requestID = UUID()
            let request = method.createRequest(with: requestID)
            try? await send(request: request)
        }
    }
}

extension Client {
    func removeStoredSubscriptionMethod(for key: SubscriptionKey) {
        subscriptionMethods.removeValue(forKey: key)
    }
}

extension Client {
    func getSubscriptionIdentifier(for method: Method) -> String? {
        switch method {
        case .blockchain(.address(.subscribe(let address))):
            return address
        case .blockchain(.transaction(.subscribe(let txid))):
            return txid
        case .blockchain(.transaction(.dsProof(.subscribe(let txid)))):
            return txid
        default:
            return nil
        }
    }
}
