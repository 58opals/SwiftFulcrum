// Response+JSONRPC.swift

import Foundation

extension Response {
    public struct JSONRPC {
        struct IdentifierExtractable: Decodable {
            let id: UUID?
            let method: String?
        }
        
        public struct Generic<Result: Decodable>: Decodable {
            let jsonrpc: String
            
            // MARK: Regular
            let id: UUID?
            let result: Result?
            let error: Response.Error.Result?
            
            // MARK: Subscription
            let method: String?
            let params: Result?
            
            enum CodingKeys: String, CodingKey {
                case jsonrpc, id, result, error, method, params
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
                self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
                self.result = try container.decodeIfPresent(Result.self, forKey: .result)
                self.error = try container.decodeIfPresent(Response.Error.Result.self, forKey: .error)
                self.method = try container.decodeIfPresent(String.self, forKey: .method)
                self.params = try container.decodeIfPresent(Result.self, forKey: .params)
            }
        }
    }
}

extension Response.JSONRPC {
    static func extractIdentifier(from data: Data) throws -> Response.Identifier {
        let response = try JSONRPC.Coder.decoder.decode(Response.JSONRPC.IdentifierExtractable.self, from: data)
        switch (response.id, response.method) {
        case let (id?, nil):
            return .uuid(id)
        case let (nil, string?):
            return .string(string)
        default:
            throw Response.JSONRPC.Error.wrongResponseType
        }
    }
}

extension Response.JSONRPC.Generic {
    func getResponseType() throws -> Response.Kind<Result> {
        switch (id, result, error, method, params) {
        case let (id?, result?, _, _, _):
            return .regular(Response.Regular(id: id, result: result))
        case let (_, _, _, method?, params?):
            return .subscription(Response.Subscription(methodPath: method, result: params))
        case let (id?, _, error?, _, _):
            return .error(Response.Error(id: id, error: error))
        case let (id?, .none, _, _, _):
            return .empty(id)
        default:
            throw Response.JSONRPC.Error.cannotIdentifyResponseType(id)
        }
    }
}
