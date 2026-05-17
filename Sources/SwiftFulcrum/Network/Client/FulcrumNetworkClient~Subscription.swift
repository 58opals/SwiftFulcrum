// FulcrumNetworkClient~Subscription.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    struct SubscriptionCancellationRegistration: Sendable {
        let token: FulcrumNetworkClient.Call.Token
        let registrationID: FulcrumNetworkClient.Call.Token.RegistrationID
    }
}

extension FulcrumNetworkClient {
    func dropAllStoredSubscriptions() async {
        let setupTasks = Array(subscriptionSetupTasks.values)
        pendingSubscriptionRequestIdentifiers.removeAll(keepingCapacity: false)
        subscriptionSetupRequestIdentifiers.removeAll(keepingCapacity: false)
        subscriptionSetupTasks.removeAll(keepingCapacity: false)
        for task in setupTasks {
            task.cancel()
        }

        let cleanupTasks = Array(subscriptionCleanupTasks.values)
        subscriptionCleanupTasks.removeAll(keepingCapacity: false)
        for task in cleanupTasks {
            task.cancel()
        }

        let cancellationRegistrations = Array(subscriptionCancellationRegistrations.values)
        subscriptionCancellationRegistrations.removeAll(keepingCapacity: false)
        for cancellationRegistration in cancellationRegistrations {
            await cancellationRegistration.token.unregister(cancellationRegistration.registrationID)
        }

        guard !subscriptionMethods.isEmpty else { return }
        subscriptionMethods.removeAll(keepingCapacity: false)
        activeSubscriptionRequestIdentifiers.removeAll(keepingCapacity: false)
        await recordSubscriptionRegistry()
    }
}

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
    func shouldSendUnsubscribeOnCancellation(for subscriptionKey: SubscriptionKey) -> Bool {
        subscriptionMethods[subscriptionKey] != nil
            && subscriptionSetupRequestIdentifiers[subscriptionKey] == nil
    }

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
                OpalDiagnostics.logger(category: .fulcrum).record(
                    event: .swiftFulcrumClientSubscriptionRestoreFailed,
                    level: .info,
                    traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestIdentifier),
                    fields: makeClientDiagnosticFields([
                        .swiftFulcrumPrivateField("subscription_identifier", subscriptionKey.identifier ?? ""),
                        .swiftFulcrumMethodPath(method.path),
                        .swiftFulcrumField("removed", didRemove)
                    ] + OpalDiagnostics.Field.swiftFulcrumErrorFields(error))
                )
            }
            return
        }
        let owner = self
        let restoreTask = Task<Void, Swift.Error> {

            let rawResponseStream = try await owner.registerUnaryResponse(for: requestIdentifier)
            guard await owner.isCurrentSubscriptionSetupRequestIdentifier(
                requestIdentifier,
                for: subscriptionKey
            ) else {
                return
            }

            try Task.checkCancellation()
            try await owner.send(data: requestData)
            guard await owner.isCurrentSubscriptionSetupRequestIdentifier(
                requestIdentifier,
                for: subscriptionKey
            ) else {
                return
            }

            let rawResponse = try await owner.awaitUnaryResponse(from: rawResponseStream)
            guard await owner.isCurrentSubscriptionSetupRequestIdentifier(
                requestIdentifier,
                for: subscriptionKey
            ) else {
                return
            }

            switch try SwiftFulcrum.RPC.Response.JSONRPC.classifyErasedResponse(from: rawResponse) {
            case .regular:
                await owner.clearSubscriptionSetupRequestIdentifier(requestIdentifier, for: subscriptionKey)
                await OpalDiagnostics.logger(category: .fulcrum).record(
                    event: .swiftFulcrumClientSubscriptionRestored,
                    level: .info,
                    traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestIdentifier),
                    fields: owner.makeClientDiagnosticFields([
                        .swiftFulcrumPrivateField("subscription_identifier", subscriptionKey.identifier ?? ""),
                        .swiftFulcrumMethodPath(method.path)
                    ])
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

            OpalDiagnostics.logger(category: .fulcrum).record(
                event: .swiftFulcrumClientSubscriptionRestoreFailed,
                level: .info,
                traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestIdentifier),
                fields: makeClientDiagnosticFields([
                    .swiftFulcrumPrivateField("subscription_identifier", subscriptionKey.identifier ?? ""),
                    .swiftFulcrumMethodPath(method.path),
                    .swiftFulcrumField("removed", didRemove)
                ] + OpalDiagnostics.Field.swiftFulcrumErrorFields(error))
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
    func recordSubscriptionCancellationRegistration(
        _ cancellationRegistration: SubscriptionCancellationRegistration?,
        for subscriptionKey: SubscriptionKey
    ) async {
        guard let cancellationRegistration else { return }

        if let existingRegistration = subscriptionCancellationRegistrations.updateValue(
            cancellationRegistration,
            forKey: subscriptionKey
        ) {
            await existingRegistration.token.unregister(existingRegistration.registrationID)
        }
    }

    func clearSubscriptionCancellationRegistration(for subscriptionKey: SubscriptionKey) async {
        guard let cancellationRegistration = subscriptionCancellationRegistrations.removeValue(forKey: subscriptionKey) else {
            return
        }

        await cancellationRegistration.token.unregister(cancellationRegistration.registrationID)
    }
}

extension FulcrumNetworkClient {
    func recordActiveSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        activeSubscriptionRequestIdentifiers[subscriptionKey] = requestIdentifier
    }

    func isCurrentActiveSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) -> Bool {
        activeSubscriptionRequestIdentifiers[subscriptionKey] == requestIdentifier
    }
}

extension FulcrumNetworkClient {
    func recordPendingSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        pendingSubscriptionRequestIdentifiers[subscriptionKey] = requestIdentifier
    }

    func isCurrentPendingSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) -> Bool {
        pendingSubscriptionRequestIdentifiers[subscriptionKey] == requestIdentifier
    }

    func clearPendingSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        guard pendingSubscriptionRequestIdentifiers[subscriptionKey] == requestIdentifier else { return }
        pendingSubscriptionRequestIdentifiers.removeValue(forKey: subscriptionKey)
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
        sendUnsubscribe: Bool = false,
        preferCurrentSetupRequest: Bool = false,
        requireMatchingActiveRequestIdentifier: Bool = false
    ) async -> Bool {
        if let task = subscriptionCleanupTasks[subscriptionKey] {
            return await task.value
        }

        let owner = self
        let task = Task<Bool, Never> {

            let didRemove = await owner.cleanUpSubscriptionSetup(
                for: subscriptionKey,
                requestIdentifier: requestIdentifier,
                error: error,
                preferCurrentSetupRequest: preferCurrentSetupRequest,
                requireMatchingActiveRequestIdentifier: requireMatchingActiveRequestIdentifier
            )

            guard sendUnsubscribe,
                  didRemove,
                  let method = await owner.makeUnsubscribeMethod(for: subscriptionKey) else {
                return didRemove
            }

            let request = method.createRequest(with: UUID())
            guard let requestData = request.data else {
                return didRemove
            }

            await Task.yield()
            guard await owner.shouldSendDeferredUnsubscribe(for: subscriptionKey) else {
                return didRemove
            }

            try? await owner.send(data: requestData)
            return didRemove
        }

        subscriptionCleanupTasks[subscriptionKey] = task
        let didRemove = await task.value
        subscriptionCleanupTasks.removeValue(forKey: subscriptionKey)
        return didRemove
    }
}

extension FulcrumNetworkClient {
    func shouldSendDeferredUnsubscribe(for subscriptionKey: SubscriptionKey) -> Bool {
        pendingSubscriptionRequestIdentifiers[subscriptionKey] == nil
            && subscriptionSetupRequestIdentifiers[subscriptionKey] == nil
            && activeSubscriptionRequestIdentifiers[subscriptionKey] == nil
            && subscriptionMethods[subscriptionKey] == nil
    }
}

extension FulcrumNetworkClient {
    @discardableResult
    func removeStoredSubscriptionMethod(
        for key: SubscriptionKey,
        requestIdentifier: UUID,
        requireMatchingActiveRequestIdentifier: Bool
    ) async -> Bool {
        if requireMatchingActiveRequestIdentifier,
           activeSubscriptionRequestIdentifiers[key] != requestIdentifier {
            return false
        }
        activeSubscriptionRequestIdentifiers.removeValue(forKey: key)
        guard subscriptionMethods.removeValue(forKey: key) != nil else { return false }
        return true
    }

    @discardableResult
    func cleanUpSubscriptionSetup(for subscriptionKey: SubscriptionKey,
                                  requestIdentifier: UUID,
                                  error: Swift.Error? = nil,
                                  preferCurrentSetupRequest: Bool = false,
                                  requireMatchingActiveRequestIdentifier: Bool = false) async -> Bool {
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
        let isCurrentActiveSubscription = isCurrentActiveSubscriptionRequestIdentifier(
            requestIdentifier,
            for: subscriptionKey
        )

        let shouldRemoveCurrentSubscription = !requireMatchingActiveRequestIdentifier || isCurrentActiveSubscription

        if shouldRemoveCurrentSubscription {
            await router.cancel(identifier: .string(subscriptionKey.string), error: error)
            await clearSubscriptionCancellationRegistration(for: subscriptionKey)
        }

        let didRemove = await removeStoredSubscriptionMethod(
            for: subscriptionKey,
            requestIdentifier: requestIdentifier,
            requireMatchingActiveRequestIdentifier: requireMatchingActiveRequestIdentifier
        )

        if didRemove {
            OpalDiagnostics.logger(category: .fulcrum).record(
                event: .swiftFulcrumClientSubscriptionRemoved,
                level: .info,
                traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestIdentifier),
                fields: makeClientDiagnosticFields([
                    .swiftFulcrumPrivateField("subscription_identifier", subscriptionKey.identifier ?? ""),
                    .swiftFulcrumField("method_path", subscriptionKey.methodPath.rawValue),
                    .swiftFulcrumField("subscription_count", subscriptionMethods.count)
                ])
            )
            await recordSubscriptionRegistry()
        }

        await recordClientState(inflightUnaryCallCount: inflightCount)

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
        recordPendingSubscriptionRequestIdentifier(requestIdentifier, for: subscriptionKey)
        defer {
            clearPendingSubscriptionRequestIdentifier(requestIdentifier, for: subscriptionKey)
        }

        await awaitPendingSubscriptionCleanup(for: subscriptionKey)
        try Task.checkCancellation()
        guard isCurrentPendingSubscriptionRequestIdentifier(requestIdentifier, for: subscriptionKey) else {
            throw CancellationError()
        }
        recordSubscriptionSetupRequestIdentifier(requestIdentifier, for: subscriptionKey)
        try await router.addStream(
            key: subscriptionKey.string,
            continuation: rawContinuation
        )
        recordActiveSubscriptionRequestIdentifier(requestIdentifier, for: subscriptionKey)
        subscriptionMethods[subscriptionKey] = method

        OpalDiagnostics.logger(category: .fulcrum).record(
            event: .swiftFulcrumClientSubscriptionAdded,
            level: .info,
            traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestIdentifier),
            fields: makeClientDiagnosticFields([
                .swiftFulcrumPrivateField("subscription_identifier", subscriptionKey.identifier ?? ""),
                .swiftFulcrumMethodPath(method.path),
                .swiftFulcrumField("subscription_count", subscriptionMethods.count)
            ])
        )
        await recordSubscriptionRegistry()
        await recordClientState()

        rawContinuation.onTermination = { @Sendable [weak self] _ in
            guard let self else { return }

            Task {
                _ = await self.scheduleSubscriptionCleanup(
                    for: subscriptionKey,
                    requestIdentifier: requestIdentifier,
                    sendUnsubscribe: true,
                    preferCurrentSetupRequest: true,
                    requireMatchingActiveRequestIdentifier: true
                )
            }
        }
    }
}
