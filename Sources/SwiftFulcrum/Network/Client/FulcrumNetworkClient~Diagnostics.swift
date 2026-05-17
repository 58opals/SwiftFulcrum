// FulcrumNetworkClient~Diagnostics.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func makeClientDiagnosticFields(_ fields: [OpalDiagnostics.Field] = []) -> [OpalDiagnostics.Field] {
        [.swiftFulcrumField("client_id", id)] + fields
    }

    func makeClientTransportDiagnosticFields(_ fields: [OpalDiagnostics.Field] = []) async -> [OpalDiagnostics.Field] {
        await makeClientDiagnosticFields([
            .swiftFulcrumEndpointURL(transport.endpoint),
            .swiftFulcrumField("reconnect_attempts", transport.reconnectAttempts),
            .swiftFulcrumField("reconnect_successes", transport.reconnectSuccesses)
        ] + fields)
    }

    func makeRequestDiagnosticFields(
        methodPath: String,
        _ fields: [OpalDiagnostics.Field] = []
    ) -> [OpalDiagnostics.Field] {
        makeClientDiagnosticFields([.swiftFulcrumMethodPath(methodPath)] + fields)
    }

    func makeRequestFailureDiagnosticFields(
        methodPath: String,
        error: Swift.Error
    ) -> [OpalDiagnostics.Field] {
        makeRequestDiagnosticFields(
            methodPath: methodPath,
            OpalDiagnostics.Field.swiftFulcrumErrorFields(error)
        )
    }

    func recordClientState(inflightUnaryCallCount: Int? = nil) async {
        let inflightCount = if let inflightUnaryCallCount {
            inflightUnaryCallCount
        } else {
            await router.makeInflightUnaryCallCount()
        }
        let fields = await makeClientTransportDiagnosticFields([
            .swiftFulcrumField("inflight_unary_call_count", inflightCount),
            .swiftFulcrumField("active_subscription_count", subscriptionMethods.count)
        ])

        OpalDiagnostics.logger(category: .fulcrum).record(
            event: .swiftFulcrumClientStateUpdated,
            level: .debug,
            fields: fields
        )
    }

    func recordSubscriptionRegistry() async {
        let endpoint = await transport.endpoint
        let fields: [OpalDiagnostics.Field] = [
            .swiftFulcrumField("client_id", id),
            .swiftFulcrumEndpointURL(endpoint),
            .swiftFulcrumField("subscription_count", subscriptionMethods.count)
        ]

        OpalDiagnostics.logger(category: .fulcrum).record(
            event: .swiftFulcrumClientSubscriptionsUpdated,
            level: .debug,
            fields: fields
        )
    }
}
