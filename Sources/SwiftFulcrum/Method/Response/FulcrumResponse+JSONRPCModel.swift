// FulcrumResponse+JSONRPCModel.swift

import Foundation

extension FulcrumResponse {
    public struct JSONRPCModel {
        struct IdentifierExtractableModel: Decodable, Sendable {
            let id: UUID?
            let method: String?
        }
        
        public struct GenericModel<ResultModel: Decodable>: Decodable {
            let jsonrpc: String
            
            // MARK: RegularModel
            let id: UUID?
            let result: ResultModel?
            let error: FulcrumResponse.Error.ResultModel?
            
            // MARK: SubscriptionModel
            let method: String?
            let params: ResultModel?
            
            private let hasResultKey: Bool
            private let hasParamsKey: Bool
            var hasResult: Bool { hasResultKey }
            var hasParams: Bool { hasParamsKey }
            
            enum CodingKeysModel: String, CodingKey {
                case jsonrpc, id, result, error, method, params
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeysModel.self)
                self.jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
                self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
                self.result = try container.decodeIfPresent(ResultModel.self, forKey: .result)
                self.error = try container.decodeIfPresent(FulcrumResponse.Error.ResultModel.self, forKey: .error)
                self.method = try container.decodeIfPresent(String.self, forKey: .method)
                self.params = try container.decodeIfPresent(ResultModel.self, forKey: .params)
                self.hasResultKey = container.contains(.result)
                self.hasParamsKey = container.contains(.params)
            }
        }
    }
}

extension FulcrumResponse.JSONRPCModel: Sendable {}
extension FulcrumResponse.JSONRPCModel.GenericModel: Sendable where ResultModel: Sendable {}

extension FulcrumResponse.JSONRPCModel {
    static func extractIdentifier(from data: Data) throws -> FulcrumResponse.IdentifierModel {
        let response = try JSONRPCModel.CoderModel.decoder.decode(FulcrumResponse.JSONRPCModel.IdentifierExtractableModel.self, from: data)
        switch (response.id, response.method) {
        case let (id?, nil):
            return .uuid(id)
        case let (nil, string?):
            return .string(string)
        default:
            throw FulcrumResponse.JSONRPCModel.Error.wrongResponseType
        }
    }
}

extension FulcrumResponse.JSONRPCModel.GenericModel {
    func determineResponseType() throws -> FulcrumResponse.KindModel<ResultModel> {
        if let id,
           error == nil,
           method == nil,
           result == nil,
           hasResult {
            if let nilProducer = FulcrumResponse.JSONRPCModel.ResultNilProducerModel.produceNilIfOptional(ResultModel.self) {
                return .regular(FulcrumResponse.RegularModel(id: id, result: nilProducer))
            }
        }
        
        
        switch (id, result, error, method, params) {
        case let (id?, result?, _, _, _):
            return .regular(FulcrumResponse.RegularModel(id: id, result: result))
        case let (_, _, _, method?, params?):
            return .subscription(FulcrumResponse.SubscriptionModel(methodPath: method, result: params))
        case let (id?, _, error?, _, _):
            return .error(FulcrumResponse.Error(id: id, error: error))
        case let (id?, .none, _, _, _):
            return .empty(id)
        default:
            throw FulcrumResponse.JSONRPCModel.Error.cannotIdentifyResponseType(id)
        }
    }
}

extension FulcrumResponse.JSONRPCModel {
    fileprivate protocol NilConstructibleModel { static var nilValue: Self { get } }
    private enum ResultNilProducerModel {
        static func produceNilIfOptional<T>(_ type: T.Type) -> T? {
            guard let optionalType = T.self as? NilConstructibleModel.Type else { return nil }
            return optionalType.nilValue as? T
        }
    }
}

extension Optional: FulcrumResponse.JSONRPCModel.NilConstructibleModel {
    static var nilValue: Self { nil }
}
