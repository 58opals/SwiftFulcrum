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
    @discardableResult
    func removeStoredSubscriptionMethod(for key: SubscriptionKey) async -> Bool {
        guard subscriptionMethods.removeValue(forKey: key) != nil else { return false }
        return true
    }
    
    @discardableResult
    func cleanUpSubscriptionSetup(for subscriptionKey: SubscriptionKey,
                                  requestIdentifier: UUID,
                                  error: Swift.Error? = nil) async -> Bool {
        let inflightCount = await router.cancel(identifier: .uuid(requestIdentifier), error: error)
        await router.cancel(identifier: .string(subscriptionKey.string), error: error)
        
        let didRemove = await removeStoredSubscriptionMethod(for: subscriptionKey)
        
        if didRemove {
            emitLog(.info,
                    "subscription_registry.removed",
                    metadata: [
                        "identifier": subscriptionKey.identifier ?? "",
                        "method": subscriptionKey.methodPath,
                        "subscriptionCount": String(subscriptionMethods.count)
                    ]
            )
            await publishSubscriptionRegistry()
        }
        
        await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
        
        return didRemove
    }
}

extension Client {
    func setUpSubscriptionLifecycle(
        rawContinuation: AsyncThrowingStream<Data, Swift.Error>.Continuation,
        subscriptionKey: SubscriptionKey,
        method: Method,
        requestIdentifier: UUID
    ) async throws {
        try await router.addStream(
            key: subscriptionKey.string,
            continuation: rawContinuation
        )
        subscriptionMethods[subscriptionKey] = method
        
        emitLog(.info,
                "subscription_registry.added",
                metadata: [
                    "identifier": subscriptionKey.identifier ?? "",
                    "method": method.path,
                    "subscriptionCount": String(subscriptionMethods.count)
                ]
        )
        await publishSubscriptionRegistry()
        await publishDiagnosticsSnapshot()
        
        rawContinuation.onTermination = { @Sendable [weak self] _ in
            guard let self else { return }
            
            Task {
                let removed = await self.cleanUpSubscriptionSetup(
                    for: subscriptionKey,
                    requestIdentifier: requestIdentifier
                )
                
                if removed, let method = await self.makeUnsubscribeMethod(for: subscriptionKey) {
                    let request = method.createRequest(with: UUID())
                    try? await self.send(request: request)
                }
            }
        }
    }
}
