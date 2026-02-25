// FulcrumResponse.swift

import Foundation

public struct FulcrumResponse {
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

extension FulcrumResponse {
    public enum KindModel<ResultModel: Decodable> {
        case empty(UUID)
        case regular(FulcrumResponse.RegularModel<ResultModel>)
        case subscription(FulcrumResponse.SubscriptionModel<ResultModel>)
        case error(FulcrumResponse.Error)
    }
    
    public enum IdentifierModel {
        case uuid(UUID)
        case string(String)
    }
}

extension FulcrumResponse.IdentifierModel: Hashable, Sendable {}
extension FulcrumResponse.RegularModel: Sendable where ResultModel: Sendable {}
extension FulcrumResponse.SubscriptionModel: Sendable where ResultModel: Sendable {}
extension FulcrumResponse.KindModel: Sendable where ResultModel: Sendable {}
