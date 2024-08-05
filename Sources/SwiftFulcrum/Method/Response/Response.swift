import Foundation

public struct Response {
    struct Regular<Result: Decodable> {
        let id: UUID
        let result: Result
    }
    
    struct Subscription<Result: Decodable> {
        let methodPath: String
        let result: Result
    }
    
    struct Error: Decodable {
        struct Result: Decodable {
            let code: Int
            let message: String
        }
        
        let id: UUID
        let error: Result
    }
}

extension Response {
    enum Kind<Result: Decodable> {
        case empty(UUID)
        case regular(Response.Regular<Result>)
        case subscription(Response.Subscription<Result>)
        case error(Response.Error)
    }
}
