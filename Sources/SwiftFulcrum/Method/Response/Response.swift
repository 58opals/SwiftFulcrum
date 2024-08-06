import Foundation

public struct Response {
    public struct Regular<Result: Decodable> {
        let id: UUID
        let result: Result
    }
    
    public struct Subscription<Result: Decodable> {
        let methodPath: String
        let result: Result
    }
    
    public struct Error: Decodable {
        public struct Result: Decodable {
            let code: Int
            let message: String
        }
        
        let id: UUID
        let error: Result
    }
}

extension Response {
    public enum Kind<Result: Decodable> {
        case empty(UUID)
        case regular(Response.Regular<Result>)
        case subscription(Response.Subscription<Result>)
        case error(Response.Error)
    }
}
