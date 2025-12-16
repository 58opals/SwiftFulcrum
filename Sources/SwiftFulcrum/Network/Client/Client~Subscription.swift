// Client~Subscription.swift

import Foundation

extension Client {
    func makeUnsubscribeMethod(for key: SubscriptionKey) -> Method? {
        switch key.methodPath {
        case "blockchain.scripthash.subscribe":
            guard let id = key.identifier else { return nil }
            return .blockchain(.scripthash(.unsubscribe(scripthash: id)))
        case "blockchain.address.subscribe":
            guard let id = key.identifier else { return nil }
            return .blockchain(.address(.unsubscribe(address: id)))
        case "blockchain.headers.subscribe":
            return .blockchain(.headers(.unsubscribe))
        case "blockchain.transaction.subscribe":
            guard let id = key.identifier else { return nil }
            return .blockchain(.transaction(.unsubscribe(transactionHash: id)))
        case "blockchain.transaction.dsproof.subscribe":
            guard let id = key.identifier else { return nil }
            return .blockchain(.transaction(.dsProof(.unsubscribe(transactionHash: id))))
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
    func removeStoredSubscriptionMethod(for key: SubscriptionKey) async {
        if let removed = subscriptionMethods.removeValue(forKey: key) {
            await emitLog(.info,
                          "subscription_registry.removed",
                          metadata: [
                            "identifier": key.identifier ?? "",
                            "method": key.methodPath,
                            "subscriptionCount": String(subscriptionMethods.count)
                          ]
            )
            await publishSubscriptionRegistry()
            await publishDiagnosticsSnapshot()
        }
    }
}

extension Client {
    func deriveSubscriptionIdentifier(for method: Method) -> String? {
        switch method {
        case .blockchain(.scripthash(.subscribe(scripthash: let scripthash))):
            return scripthash
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
