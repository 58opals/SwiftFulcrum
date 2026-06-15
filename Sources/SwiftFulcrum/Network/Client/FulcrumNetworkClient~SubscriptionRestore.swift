// FulcrumNetworkClient~SubscriptionRestore.swift

import Foundation
import OpalDiagnostics

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
