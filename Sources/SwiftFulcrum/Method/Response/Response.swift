// Response.swift

import Foundation

public struct Response {
    public struct RegularModel<ResultModel: Decodable> {
        let id: UUID
        let result: ResultModel
    }
    
    public struct SubscriptionModel<ResultModel: Decodable> {
        let methodPath: String
        let result: ResultModel
    }
    
    public struct Error: Decodable, Sendable {
        public struct ResultModel: Decodable, Sendable {
            let code: Int
            let message: String
        }
        
        let id: UUID
        let error: ResultModel
    }
}

extension Response {
    public enum KindModel<ResultModel: Decodable> {
        case empty(UUID)
        case regular(Response.RegularModel<ResultModel>)
        case subscription(Response.SubscriptionModel<ResultModel>)
        case error(Response.Error)
    }
    
    public enum IdentifierModel {
        case uuid(UUID)
        case string(String)
    }
}

extension Response.IdentifierModel: Hashable, Sendable {}
extension Response.RegularModel: Sendable where ResultModel: Sendable {}
extension Response.SubscriptionModel: Sendable where ResultModel: Sendable {}
extension Response.KindModel: Sendable where ResultModel: Sendable {}
