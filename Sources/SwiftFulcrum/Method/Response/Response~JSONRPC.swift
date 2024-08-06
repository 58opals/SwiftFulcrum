import Foundation

extension Response {
    public struct JSONRPC {
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
                
                if let id = try? container.decodeIfPresent(UUID.self, forKey: .id) {
                    // MARK: Regular - decode
                    self.id = id
                    
                    self.result = try? container.decodeIfPresent(Result.self, forKey: .result)
                    self.error = try? container.decodeIfPresent(Response.Error.Result.self, forKey: .error)
                    
                    self.method = nil
                    self.params = nil
                    
                } else if let method = try? container.decodeIfPresent(String.self, forKey: .method) {
                    // MARK: Subscription - decode
                    self.id = nil
                    self.result = nil
                    self.error = nil
                    
                    self.method = method
                    self.params = try? container.decodeIfPresent(Result.self, forKey: .params)
                    
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid JSON-RPC response format.")
                }
            }
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
        case let (id?, .none, _, _, _):
            return .empty(id)
        case let (id?, _, error?, _, _):
            return .error(Response.Error(id: id, error: error))
        default:
            throw Error.cannotIdentifyResponseType(id)
        }
    }
}
