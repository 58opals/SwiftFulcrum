import Foundation

extension SwiftFulcrum.RPC.Method {
    var subscriptionPath: SubscriptionPathConfiguration? {
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
