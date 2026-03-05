// SwiftFulcrum.RPC.Response.swift

import Foundation

public extension SwiftFulcrum.RPC {
    struct Response {
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
}

extension SwiftFulcrum.RPC.Response {
    public enum KindModel<ResultModel: Decodable> {
        case empty(UUID)
        case regular(SwiftFulcrum.RPC.Response.RegularModel<ResultModel>)
        case subscription(SwiftFulcrum.RPC.Response.SubscriptionModel<ResultModel>)
        case error(SwiftFulcrum.RPC.Response.Error)
    }
    
    public enum IdentifierModel {
        case uuid(UUID)
        case string(String)
    }
}

extension SwiftFulcrum.RPC.Response.IdentifierModel: Hashable, Sendable {}
extension SwiftFulcrum.RPC.Response.RegularModel: Sendable where ResultModel: Sendable {}
extension SwiftFulcrum.RPC.Response.SubscriptionModel: Sendable where ResultModel: Sendable {}
extension SwiftFulcrum.RPC.Response.KindModel: Sendable where ResultModel: Sendable {}
