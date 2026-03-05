// SwiftFulcrum.RPC.Response+JSONRPCModel.swift

import Foundation

extension SwiftFulcrum.RPC.Response {
    public struct JSONRPCModel {
        struct IdentifierExtractable: Decodable, Sendable {
            let id: UUID?
            let method: String?
        }
        
        public struct Generic<ResultModel: Decodable>: Decodable {
            let jsonrpc: String
            
            // MARK: RegularModel
            let id: UUID?
            let result: ResultModel?
            let error: SwiftFulcrum.RPC.Response.Error.ResultModel?
            
            // MARK: SubscriptionModel
            let method: String?
            let params: ResultModel?
            
            private let hasResultKey: Bool
            private let hasParamsKey: Bool
            var hasResult: Bool { hasResultKey }
            var hasParams: Bool { hasParamsKey }
            
            enum CodingKeys: String, CodingKey {
                case jsonrpc, id, result, error, method, params
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
                self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
                self.result = try container.decodeIfPresent(ResultModel.self, forKey: .result)
                self.error = try container.decodeIfPresent(SwiftFulcrum.RPC.Response.Error.ResultModel.self, forKey: .error)
                self.method = try container.decodeIfPresent(String.self, forKey: .method)
                self.params = try container.decodeIfPresent(ResultModel.self, forKey: .params)
                self.hasResultKey = container.contains(.result)
                self.hasParamsKey = container.contains(.params)
            }
        }
    }
}

extension SwiftFulcrum.RPC.Response.JSONRPCModel: Sendable {}
extension SwiftFulcrum.RPC.Response.JSONRPCModel.Generic: Sendable where ResultModel: Sendable {}

extension SwiftFulcrum.RPC.Response.JSONRPCModel {
    static func extractIdentifier(from data: Data) throws -> SwiftFulcrum.RPC.Response.IdentifierModel {
        let response = try JSONRPCModel.Coder.decoder.decode(SwiftFulcrum.RPC.Response.JSONRPCModel.IdentifierExtractable.self, from: data)
        switch (response.id, response.method) {
        case let (id?, nil):
            return .uuid(id)
        case let (nil, string?):
            return .string(string)
        default:
            throw SwiftFulcrum.RPC.Response.JSONRPCModel.Error.wrongResponseType
        }
    }
}

extension SwiftFulcrum.RPC.Response.JSONRPCModel.Generic {
    func determineResponseType() throws -> SwiftFulcrum.RPC.Response.KindModel<ResultModel> {
        if let id,
           error == nil,
           method == nil,
           result == nil,
           hasResult {
            if let nilProducer = SwiftFulcrum.RPC.Response.JSONRPCModel.ResultNilProducer.produceNilIfOptional(ResultModel.self) {
                return .regular(SwiftFulcrum.RPC.Response.RegularModel(id: id, result: nilProducer))
            }
        }
        
        
        switch (id, result, error, method, params) {
        case let (id?, result?, _, _, _):
            return .regular(SwiftFulcrum.RPC.Response.RegularModel(id: id, result: result))
        case let (_, _, _, method?, params?):
            return .subscription(SwiftFulcrum.RPC.Response.SubscriptionModel(methodPath: method, result: params))
        case let (id?, _, error?, _, _):
            return .error(SwiftFulcrum.RPC.Response.Error(id: id, error: error))
        case let (id?, .none, _, _, _):
            return .empty(id)
        default:
            throw SwiftFulcrum.RPC.Response.JSONRPCModel.Error.cannotIdentifyResponseType(id)
        }
    }
}

extension SwiftFulcrum.RPC.Response.JSONRPCModel {
    fileprivate protocol NilConstructible { static var nilValue: Self { get } }
    private enum ResultNilProducer {
        static func produceNilIfOptional<T>(_ type: T.Type) -> T? {
            guard let optionalType = T.self as? NilConstructible.Type else { return nil }
            return optionalType.nilValue as? T
        }
    }
}

extension Optional: SwiftFulcrum.RPC.Response.JSONRPCModel.NilConstructible {
    static var nilValue: Self { nil }
}
