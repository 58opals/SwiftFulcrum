// FulcrumNetworkClient~SubscriptionRestore.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func resubscribeStoredMethods(
        reconnectSuccessCount: Int,
        recoveryGeneration: UInt64
    ) async throws {
        try Task.checkCancellation()
        try await ensureSubscriptionRestoreIsCurrent(
            reconnectSuccessCount: reconnectSuccessCount,
            recoveryGeneration: recoveryGeneration
        )
        try await awaitPendingSubscriptionCleanups()
        try Task.checkCancellation()
        try await ensureSubscriptionRestoreIsCurrent(
            reconnectSuccessCount: reconnectSuccessCount,
            recoveryGeneration: recoveryGeneration
        )
        let methods = subscriptionRegistry.makeStoredMethods()
        for (subscriptionKey, method) in methods {
            try Task.checkCancellation()
            try await ensureSubscriptionRestoreIsCurrent(
                reconnectSuccessCount: reconnectSuccessCount,
                recoveryGeneration: recoveryGeneration
            )
            try await restoreStoredSubscription(
                method,
                for: subscriptionKey,
                reconnectSuccessCount: reconnectSuccessCount,
                recoveryGeneration: recoveryGeneration
            )
        }
        try Task.checkCancellation()
        try await ensureSubscriptionRestoreIsCurrent(
            reconnectSuccessCount: reconnectSuccessCount,
            recoveryGeneration: recoveryGeneration
        )
    }

    func restoreStoredSubscription(
        _ method: SwiftFulcrum.RPC.Method,
        for subscriptionKey: SubscriptionKey,
        reconnectSuccessCount: Int,
        recoveryGeneration: UInt64? = nil
    ) async throws {
        let restoreReconnectSuccessCount = reconnectSuccessCount
        let restoreRecoveryGeneration =
            recoveryGeneration
            ?? connectionRecoveryGeneration
        try await ensureSubscriptionRestoreIsCurrent(
            reconnectSuccessCount: restoreReconnectSuccessCount,
            recoveryGeneration: restoreRecoveryGeneration
        )

        let requestIdentifier = UUID()
        let request = method.createRequest(with: requestIdentifier)
        guard let requestData = request.data else {
            let error = SwiftFulcrum.Client.Error.coding(.encode(nil))
            let didRemove = await cleanUpSubscriptionSetup(
                for: subscriptionKey,
                requestIdentifier: requestIdentifier,
                reason: .streamTermination(error)
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
            try Task.checkCancellation()
            try await owner.ensureSubscriptionRestoreIsCurrent(
                reconnectSuccessCount: restoreReconnectSuccessCount,
                recoveryGeneration: restoreRecoveryGeneration
            )
            let rawResponseStream = try await owner.registerUnaryResponse(for: requestIdentifier)
            guard await owner.isCurrentSubscriptionSetupRequestIdentifier(
                requestIdentifier,
                for: subscriptionKey
            ) else {
                throw CancellationError()
            }
            try await owner.ensureSubscriptionRestoreIsCurrent(
                reconnectSuccessCount: restoreReconnectSuccessCount,
                recoveryGeneration: restoreRecoveryGeneration
            )

            try Task.checkCancellation()
            try await owner.send(data: requestData)
            guard await owner.isCurrentSubscriptionSetupRequestIdentifier(
                requestIdentifier,
                for: subscriptionKey
            ) else {
                throw CancellationError()
            }
            try await owner.ensureSubscriptionRestoreIsCurrent(
                reconnectSuccessCount: restoreReconnectSuccessCount,
                recoveryGeneration: restoreRecoveryGeneration
            )

            let rawResponse = try await owner.awaitUnaryResponse(from: rawResponseStream)
            guard await owner.isCurrentSubscriptionSetupRequestIdentifier(
                requestIdentifier,
                for: subscriptionKey
            ) else {
                throw CancellationError()
            }
            try await owner.ensureSubscriptionRestoreIsCurrent(
                reconnectSuccessCount: restoreReconnectSuccessCount,
                recoveryGeneration: restoreRecoveryGeneration
            )

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

        recordSubscriptionSetupRequestIdentifier(requestIdentifier, task: restoreTask, for: subscriptionKey)

        do {
            try await withTaskCancellationHandler {
                try await restoreTask.value
            } onCancel: {
                restoreTask.cancel()
                Task {
                    await owner.cancelUnary(requestIdentifier, error: CancellationError())
                }
            }
            try await ensureSubscriptionRestoreIsCurrent(
                reconnectSuccessCount: restoreReconnectSuccessCount,
                recoveryGeneration: restoreRecoveryGeneration
            )
        } catch {
            if await isSubscriptionRestoreSuperseded(
                reconnectSuccessCount: restoreReconnectSuccessCount,
                recoveryGeneration: restoreRecoveryGeneration
            ) {
                await preserveStoredSubscriptionAfterSupersededRestore(
                    for: subscriptionKey,
                    requestIdentifier: requestIdentifier
                )
                throw CancellationError()
            }

            let shouldLogFailure = isCurrentSubscriptionSetupRequestIdentifier(
                requestIdentifier,
                for: subscriptionKey
            )
            let didRemove = await cleanUpSubscriptionSetup(
                for: subscriptionKey,
                requestIdentifier: requestIdentifier,
                reason: .streamTermination(error)
            )
            if shouldLogFailure || didRemove {
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

            if Task.isCancelled {
                throw CancellationError()
            }
        }
    }
}
