// FulcrumNetworkClient~Subscription.swift

import Foundation

extension FulcrumNetworkClient {
    func makeUnsubscribeMethod(for key: SubscriptionKey) -> SwiftFulcrum.RPC.Method? {
        switch key.methodPath {
        case .scriptHash:
            guard let id = key.identifier else { return nil }
            return .blockchain(.scripthash(.unsubscribe(scripthash: id)))
        case .address:
            guard let id = key.identifier else { return nil }
            return .blockchain(.address(.unsubscribe(address: id)))
        case .headers:
            return .blockchain(.headers(.unsubscribe))
        case .transaction:
            guard let id = key.identifier else { return nil }
            return .blockchain(.transaction(.unsubscribe(transactionHash: id)))
        case .transactionDoubleSpendProof:
            guard let id = key.identifier else { return nil }
            return .blockchain(.transaction(.dsProof(.unsubscribe(transactionHash: id))))
        }
    }
}

extension FulcrumNetworkClient {
    func deriveSubscriptionIdentifier(for method: SwiftFulcrum.RPC.Method) -> String? {
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

extension FulcrumNetworkClient {
    func resubscribeStoredMethods() async {
        await awaitPendingSubscriptionCleanups()
        let methods = Array(subscriptionMethods)
        for (subscriptionKey, method) in methods {
            await restoreStoredSubscription(method, for: subscriptionKey)
        }
    }
}

extension FulcrumNetworkClient {
    func restoreStoredSubscription(_ method: SwiftFulcrum.RPC.Method, for subscriptionKey: SubscriptionKey) async {
        let requestIdentifier = UUID()
        let request = method.createRequest(with: requestIdentifier)

        do {
            let rawResponseStream = try await registerUnaryResponse(for: requestIdentifier)
            try await send(request: request)
            let rawResponse = try await awaitUnaryResponse(from: rawResponseStream)

            switch try SwiftFulcrum.RPC.Response.JSONRPC.classifyErasedResponse(from: rawResponse) {
            case .regular:
                emitLog(.info,
                        "subscription_registry.restored",
                        metadata: [
                            "identifier": subscriptionKey.identifier ?? "",
                            "method": method.path
                        ]
                )
            case .error(let error):
                throw error
            case .empty(let identifier):
                throw SwiftFulcrum.Client.Error.client(.emptyResponse(identifier))
            }
        } catch {
            let didRemove = await cleanUpSubscriptionSetup(
                for: subscriptionKey,
                requestIdentifier: requestIdentifier,
                error: error
            )

            emitLog(.error,
                    "subscription_registry.restore_failed",
                    metadata: [
                        "identifier": subscriptionKey.identifier ?? "",
                        "method": method.path,
                        "removed": String(didRemove),
                        "error": error.localizedDescription
                    ]
            )
        }
    }
}

extension FulcrumNetworkClient {
    func awaitPendingSubscriptionCleanup(for key: SubscriptionKey) async {
        guard let task = subscriptionCleanupTasks[key] else { return }
        _ = await task.value
    }

    func awaitPendingSubscriptionCleanups() async {
        let tasks = Array(subscriptionCleanupTasks.values)
        for task in tasks {
            _ = await task.value
        }
    }

    @discardableResult
    func scheduleSubscriptionCleanup(
        for subscriptionKey: SubscriptionKey,
        requestIdentifier: UUID,
        error: Swift.Error? = nil,
        sendUnsubscribe: Bool = false
    ) async -> Bool {
        if let task = subscriptionCleanupTasks[subscriptionKey] {
            return await task.value
        }

        let task = Task<Bool, Never> { [weak self] in
            guard let self else { return false }

            let didRemove = await self.cleanUpSubscriptionSetup(
                for: subscriptionKey,
                requestIdentifier: requestIdentifier,
                error: error
            )

            guard sendUnsubscribe,
                  didRemove,
                  let method = await self.makeUnsubscribeMethod(for: subscriptionKey) else {
                return didRemove
            }

            let request = method.createRequest(with: UUID())
            try? await self.send(request: request)
            return didRemove
        }

        subscriptionCleanupTasks[subscriptionKey] = task
        let didRemove = await task.value
        subscriptionCleanupTasks.removeValue(forKey: subscriptionKey)
        return didRemove
    }
}

extension FulcrumNetworkClient {
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
                        "method": subscriptionKey.methodPath.rawValue,
                        "subscriptionCount": String(subscriptionMethods.count)
                    ]
            )
            await publishSubscriptionRegistry()
        }

        await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)

        return didRemove
    }
}

extension FulcrumNetworkClient {
    func configureSubscriptionLifecycle(
        rawContinuation: AsyncThrowingStream<Data, Swift.Error>.Continuation,
        subscriptionKey: SubscriptionKey,
        method: SwiftFulcrum.RPC.Method,
        requestIdentifier: UUID
    ) async throws {
        await awaitPendingSubscriptionCleanup(for: subscriptionKey)
        try Task.checkCancellation()
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
                _ = await self.scheduleSubscriptionCleanup(
                    for: subscriptionKey,
                    requestIdentifier: requestIdentifier,
                    sendUnsubscribe: true
                )
            }
        }
    }
}
