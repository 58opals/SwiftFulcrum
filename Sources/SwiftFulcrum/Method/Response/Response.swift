import Foundation

struct Response {
    struct Regular<Result: FulcrumRegularResponseResultInitializable>: FulcrumResponseInitializable {
        let id: UUID
        let result: Result
    }
    
    struct Subscription<Result: FulcrumSubscriptionResponseResultInitializable>: FulcrumResponseInitializable {
        let methodPath: String
        let result: Result
    }
    
    struct Error: Decodable, FulcrumResponseInitializable {
        struct Result: Decodable {
            let code: Int
            let message: String
        }
        
        let id: UUID
        let error: Result
    }
}
