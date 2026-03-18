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
        guard let requestData = request.data else {
            let error = SwiftFulcrum.Client.Error.coding(.encode(nil))
            let didRemove = await cleanUpSubscriptionSetup(
                for: subscriptionKey,
                requestIdentifier: requestIdentifier,
                error: error
            )
            if didRemove {
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
            return
        }
        let restoreTask = Task<Void, Swift.Error> { [weak self] in
            guard let self else { throw CancellationError() }

            let rawResponseStream = try await self.registerUnaryResponse(for: requestIdentifier)
            guard await self.isCurrentSubscriptionSetupRequestIdentifier(
                requestIdentifier,
                for: subscriptionKey
            ) else {
                return
            }

            try Task.checkCancellation()
            try await self.send(data: requestData)
            guard await self.isCurrentSubscriptionSetupRequestIdentifier(
                requestIdentifier,
                for: subscriptionKey
            ) else {
                return
            }

            let rawResponse = try await self.awaitUnaryResponse(from: rawResponseStream)
            guard await self.isCurrentSubscriptionSetupRequestIdentifier(
                requestIdentifier,
                for: subscriptionKey
            ) else {
                return
            }

            switch try SwiftFulcrum.RPC.Response.JSONRPC.classifyErasedResponse(from: rawResponse) {
            case .regular:
                await self.clearSubscriptionSetupRequestIdentifier(requestIdentifier, for: subscriptionKey)
                await self.emitLog(.info,
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
        }

        recordSubscriptionSetupRequestIdentifier(requestIdentifier, for: subscriptionKey)
        subscriptionSetupTasks[subscriptionKey] = restoreTask

        do {
            try await restoreTask.value
        } catch {
            let shouldLogFailure = isCurrentSubscriptionSetupRequestIdentifier(
                requestIdentifier,
                for: subscriptionKey
            )
            let didRemove = await cleanUpSubscriptionSetup(
                for: subscriptionKey,
                requestIdentifier: requestIdentifier,
                error: error
            )
            guard shouldLogFailure || didRemove else { return }

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
}

extension FulcrumNetworkClient {
    func recordSubscriptionSetupRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        subscriptionSetupRequestIdentifiers[subscriptionKey] = requestIdentifier
    }

    func isCurrentSubscriptionSetupRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) -> Bool {
        subscriptionSetupRequestIdentifiers[subscriptionKey] == requestIdentifier
    }

    func clearSubscriptionSetupRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        guard subscriptionSetupRequestIdentifiers[subscriptionKey] == requestIdentifier else { return }
        subscriptionSetupRequestIdentifiers.removeValue(forKey: subscriptionKey)
        subscriptionSetupTasks.removeValue(forKey: subscriptionKey)
    }

    @discardableResult
    func cancelCurrentSubscriptionSetupRequest(
        for subscriptionKey: SubscriptionKey,
        expectedRequestIdentifier: UUID? = nil,
        error: Swift.Error? = nil
    ) async -> Int? {
        guard let currentRequestIdentifier = subscriptionSetupRequestIdentifiers[subscriptionKey] else {
            return nil
        }
        if let expectedRequestIdentifier, currentRequestIdentifier != expectedRequestIdentifier {
            return nil
        }

        let setupTask = subscriptionSetupTasks.removeValue(forKey: subscriptionKey)
        subscriptionSetupRequestIdentifiers.removeValue(forKey: subscriptionKey)
        setupTask?.cancel()
        return await router.cancel(identifier: .uuid(currentRequestIdentifier), error: error)
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
                error: error,
                preferCurrentSetupRequest: true
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
                                  error: Swift.Error? = nil,
                                  preferCurrentSetupRequest: Bool = false) async -> Bool {
        let inflightCount: Int?
        if preferCurrentSetupRequest {
            if let currentInflightCount = await cancelCurrentSubscriptionSetupRequest(
                for: subscriptionKey,
                error: error
            ) {
                inflightCount = currentInflightCount
            } else if let expectedInflightCount = await cancelCurrentSubscriptionSetupRequest(
                for: subscriptionKey,
                expectedRequestIdentifier: requestIdentifier,
                error: error
            ) {
                inflightCount = expectedInflightCount
            } else {
                inflightCount = await router.cancel(identifier: .uuid(requestIdentifier), error: error)
            }
        } else {
            if let expectedInflightCount = await cancelCurrentSubscriptionSetupRequest(
                for: subscriptionKey,
                expectedRequestIdentifier: requestIdentifier,
                error: error
            ) {
                inflightCount = expectedInflightCount
            } else {
                inflightCount = await router.cancel(identifier: .uuid(requestIdentifier), error: error)
            }
        }
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
        recordSubscriptionSetupRequestIdentifier(requestIdentifier, for: subscriptionKey)
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
