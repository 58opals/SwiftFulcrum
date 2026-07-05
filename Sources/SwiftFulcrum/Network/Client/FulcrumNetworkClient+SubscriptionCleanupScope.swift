// FulcrumNetworkClient+SubscriptionCleanupScope.swift

import Foundation

extension FulcrumNetworkClient {
    enum SubscriptionCleanupScope: Sendable {
        case request
        case currentSetupThenRequest
        case currentSetupThenActiveRequest

        var requiresActiveRequestIdentifier: Bool {
            guard case .currentSetupThenActiveRequest = self else { return false }
            return true
        }
    }
}
