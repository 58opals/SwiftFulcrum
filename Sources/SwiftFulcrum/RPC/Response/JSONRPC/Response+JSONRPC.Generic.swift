// Response+JSONRPC.Generic.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC {
    struct Generic<Payload: Decodable>: Decodable {
        let id: UUID?
        let result: Payload?
        let error: SwiftFulcrum.RPC.Response.Error.Result?
        let method: String?
        let params: Payload?

        private let hasResultKey: Bool
        private let hasParamsKey: Bool
        var hasResult: Bool { hasResultKey }
        var hasParams: Bool { hasParamsKey }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JSONRPCResponseDecodeModel.CodingKeyModel.self)
            let idKey = JSONRPCResponseDecodeModel.CodingKeyModel("id")
            let resultKey = JSONRPCResponseDecodeModel.CodingKeyModel("result")
            let errorKey = JSONRPCResponseDecodeModel.CodingKeyModel("error")
            let methodKey = JSONRPCResponseDecodeModel.CodingKeyModel("method")
            let paramsKey = JSONRPCResponseDecodeModel.CodingKeyModel("params")

            try JSONRPCResponseDecodeModel.validateVersion(in: container)
            self.id = try container.decodeIfPresent(UUID.self, forKey: idKey)
            self.result = try container.decodeIfPresent(Payload.self, forKey: resultKey)
            self.error = try container.decodeIfPresent(SwiftFulcrum.RPC.Response.Error.Result.self, forKey: errorKey)
            self.method = try container.decodeIfPresent(String.self, forKey: methodKey)
            self.params = try container.decodeIfPresent(Payload.self, forKey: paramsKey)
            self.hasResultKey = container.contains(resultKey)
            self.hasParamsKey = container.contains(paramsKey)
        }
    }
}

extension SwiftFulcrum.RPC.Response.JSONRPC.Generic: Sendable where Payload: Sendable {}

extension SwiftFulcrum.RPC.Response.JSONRPC.Generic {
    func determineResponseType() throws -> SwiftFulcrum.RPC.Response.Kind<Payload> {
        if error != nil, hasResult {
            throw JSONRPCResponseDecodeError.wrongResponseType
        }

        if let id,
           error == nil,
           method == nil,
           result == nil,
           hasResult {
            if let nilProducer = JSONRPCResponseDecodeModel.makeOptionalNilValue(Payload.self) {
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
            throw JSONRPCResponseDecodeError.cannotIdentifyResponseType(id)
        }
    }
}
