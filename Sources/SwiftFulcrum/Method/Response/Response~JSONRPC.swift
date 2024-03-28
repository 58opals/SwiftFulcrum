import Foundation

extension Response {
    struct JSONRPCGeneric<Result: Decodable>: JSONRPCObjectable, Decodable {
        let jsonrpc: String
        
        // MARK: Regular
        let id: UUID?
        let result: Result?
        let error: Error.Result?
        
        // MARK: Subscription
        let method: String?
        let params: Result?
        
        enum CodingKeys: String, CodingKey {
            case jsonrpc, id, result, error, method, params
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
            
            if let id = try? container.decodeIfPresent(UUID.self, forKey: .id) {
                // MARK: Regular - decode
                self.id = id
                
                self.result = try? container.decodeIfPresent(Result.self, forKey: .result)
                self.error = try? container.decodeIfPresent(Error.Result.self, forKey: .error)
                
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
