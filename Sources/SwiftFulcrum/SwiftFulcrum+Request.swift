import Foundation

extension SwiftFulcrum {
    public struct RegularRequest {
        let method: Method
        let resultBehavior: (UUID) -> Void
    }
    
    public struct SubscriptionRequest {
        let method: Method
        let notificationBehavior: (String) -> Void
    }
}
