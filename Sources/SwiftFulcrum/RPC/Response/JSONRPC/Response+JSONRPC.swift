import Foundation

extension SwiftFulcrum.RPC.Response {
    public struct JSONRPC {
        struct IdentifierExtractable: Decodable, Sendable {
            let id: UUID?
            let method: String?
        }
        
        public struct Generic<Payload: Decodable>: Decodable {
            let jsonrpc: String
            
            // MARK: Regular
            let id: UUID?
            let result: Payload?
            let error: SwiftFulcrum.RPC.Response.Error.Result?
            
            // MARK: Subscription
            let method: String?
            let params: Payload?
            
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
                self.result = try container.decodeIfPresent(Payload.self, forKey: .result)
                self.error = try container.decodeIfPresent(SwiftFulcrum.RPC.Response.Error.Result.self, forKey: .error)
                self.method = try container.decodeIfPresent(String.self, forKey: .method)
                self.params = try container.decodeIfPresent(Payload.self, forKey: .params)
                self.hasResultKey = container.contains(.result)
                self.hasParamsKey = container.contains(.params)
            }
        }
    }
}

extension SwiftFulcrum.RPC.Response.JSONRPC: Sendable {}
extension SwiftFulcrum.RPC.Response.JSONRPC.Generic: Sendable where Payload: Sendable {}

extension SwiftFulcrum.RPC.Response.JSONRPC {
    static func extractIdentifier(from data: Data) throws -> SwiftFulcrum.RPC.Response.Identifier {
        let response = try JSONRPCCodec.Coder.decoder.decode(SwiftFulcrum.RPC.Response.JSONRPC.IdentifierExtractable.self, from: data)
        switch (response.id, response.method) {
        case let (id?, nil):
            return .uuid(id)
        case let (nil, string?):
            return .string(string)
        default:
            throw SwiftFulcrum.RPC.Response.JSONRPC.Error.wrongResponseType
        }
    }
}

extension SwiftFulcrum.RPC.Response.JSONRPC.Generic {
    func determineResponseType() throws -> SwiftFulcrum.RPC.Response.Kind<Payload> {
        if let id,
           error == nil,
           method == nil,
           result == nil,
           hasResult {
            if let nilProducer = SwiftFulcrum.RPC.Response.JSONRPC.ResultNilProducer.produceNilIfOptional(Payload.self) {
                return .regular(SwiftFulcrum.RPC.Response.Regular(id: id, result: nilProducer))
            }
        }
        
        
        switch (id, result, error, method, params) {
        case let (id?, result?, _, _, _):
            return .regular(SwiftFulcrum.RPC.Response.Regular(id: id, result: result))
        case let (_, _, _, method?, params?):
            return .subscription(SwiftFulcrum.RPC.Response.Subscription(methodPath: method, result: params))
        case let (id?, _, error?, _, _):
            return .error(SwiftFulcrum.RPC.Response.Error(id: id, error: error))
        case let (id?, .none, _, _, _):
            return .empty(id)
        default:
            throw SwiftFulcrum.RPC.Response.JSONRPC.Error.cannotIdentifyResponseType(id)
        }
    }
}

extension SwiftFulcrum.RPC.Response.JSONRPC {
    fileprivate protocol NilConstructible { static var nilValue: Self { get } }
    private enum ResultNilProducer {
        static func produceNilIfOptional<T>(_ type: T.Type) -> T? {
            guard let optionalType = T.self as? NilConstructible.Type else { return nil }
            return optionalType.nilValue as? T
        }
    }
}

extension Optional: SwiftFulcrum.RPC.Response.JSONRPC.NilConstructible {
    static var nilValue: Self { nil }
}
