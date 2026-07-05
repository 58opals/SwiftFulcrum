// FulcrumNetworkClient+SubscriptionRecord.swift

import Foundation

extension FulcrumNetworkClient {
    struct SubscriptionRecord: Sendable {
        let method: SwiftFulcrum.RPC.Method
        let originRequestIdentifier: UUID
        var phase: SubscriptionLifecyclePhase
        var cancellationRegistration: SubscriptionCancellationRegistration?

        init(
            method: SwiftFulcrum.RPC.Method,
            phase: SubscriptionLifecyclePhase,
            originRequestIdentifier: UUID? = nil,
            cancellationRegistration: SubscriptionCancellationRegistration? = nil
        ) {
            self.method = method
            self.originRequestIdentifier = originRequestIdentifier ?? phase.requestIdentifier
            self.phase = phase
            self.cancellationRegistration = cancellationRegistration
        }
    }
}
