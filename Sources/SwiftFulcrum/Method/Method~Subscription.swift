// Method~Subscription.swift

import Foundation

extension Method {
    var subscriptionPath: SubscriptionPath? {
        switch self {
        case .blockchain(.scripthash(.subscribe)):
            return .scriptHash
        case .blockchain(.address(.subscribe)):
            return .address
        case .blockchain(.headers(.subscribe)):
            return .headers
        case .blockchain(.transaction(.subscribe)):
            return .transaction
        case .blockchain(.transaction(.dsProof(.subscribe))):
            return .transactionDoubleSpendProof
        default:
            return nil
        }
    }
    
    public var isSubscription: Bool {
        subscriptionPath != nil
    }
}
