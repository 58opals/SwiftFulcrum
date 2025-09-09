// Method~Subscription.swift

import Foundation

extension Method {
    var isSubscription: Bool {
        switch self {
        case .blockchain(.address(.subscribe)), .blockchain(.headers(.subscribe)), .blockchain(.transaction(.subscribe)), .blockchain(.transaction(.dsProof(.subscribe))):
            return true
        default:
            return false
        }
    }
}
