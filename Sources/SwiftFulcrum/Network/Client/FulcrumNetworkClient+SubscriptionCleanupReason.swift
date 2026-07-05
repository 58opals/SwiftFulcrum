// FulcrumNetworkClient+SubscriptionCleanupReason.swift

import Foundation

extension FulcrumNetworkClient {
    enum SubscriptionCleanupReason: Sendable {
        case cancellation(Swift.Error?)
        case streamTermination(Swift.Error?)
        case overflow(Swift.Error)
        case stop

        var error: Swift.Error? {
            switch self {
            case .cancellation(let error),
                 .streamTermination(let error):
                error
            case .overflow(let error):
                error
            case .stop:
                nil
            }
        }
    }
}
