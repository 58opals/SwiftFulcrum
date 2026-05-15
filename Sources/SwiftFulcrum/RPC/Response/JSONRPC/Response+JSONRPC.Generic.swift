// Response+JSONRPC.Generic.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC {
    struct Generic<Payload: Decodable>: Decodable {
        let id: UUID?
        let result: Payload?
        let error: SwiftFulcrum.RPC.Response.Error.Result?
        let method: String?
        let params: Payload?
        let hasResult: Bool
        let hasError: Bool
        let hasParams: Bool

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JSONRPCResponseDecodeModel.CodingKey.self)
            let idKey = JSONRPCResponseDecodeModel.CodingKey("id")
            let resultKey = JSONRPCResponseDecodeModel.CodingKey("result")
            let errorKey = JSONRPCResponseDecodeModel.CodingKey("error")
            let methodKey = JSONRPCResponseDecodeModel.CodingKey("method")
            let paramsKey = JSONRPCResponseDecodeModel.CodingKey("params")

            try JSONRPCResponseDecodeModel.validateVersion(in: container)
            self.id = try container.decodeIfPresent(UUID.self, forKey: idKey)
            self.result = try container.decodeIfPresent(Payload.self, forKey: resultKey)
            self.error = try container.decodeIfPresent(SwiftFulcrum.RPC.Response.Error.Result.self, forKey: errorKey)
            self.method = try container.decodeIfPresent(String.self, forKey: methodKey)
            self.params = try container.decodeIfPresent(Payload.self, forKey: paramsKey)
            self.hasResult = container.contains(resultKey)
            self.hasError = container.contains(errorKey)
            self.hasParams = container.contains(paramsKey)
        }
    }
}

extension SwiftFulcrum.RPC.Response.JSONRPC.Generic: Sendable where Payload: Sendable {}

extension SwiftFulcrum.RPC.Response.JSONRPC.Generic {
    func determineResponseType() throws -> SwiftFulcrum.RPC.Response.Kind<Payload> {
        if method != nil || hasParams {
            guard id == nil, !hasError, !hasResult, let method, let params else {
                throw JSONRPCResponseDecodeError.wrongResponseType
            }
            return .subscription(SwiftFulcrum.RPC.Response.Subscription(methodPath: method, result: params))
        }

        if hasError, hasResult {
            throw JSONRPCResponseDecodeError.wrongResponseType
        }

        if hasError, error == nil {
            throw JSONRPCResponseDecodeError.wrongResponseType
        }

        if let id, let result {
            return .regular(SwiftFulcrum.RPC.Response.Regular(id: id, result: result))
        }

        if let id, let error {
            return .error(SwiftFulcrum.RPC.Response.Error(id: id, error: error))
        }

        if let id, hasResult {
            guard let nilProducer = JSONRPCResponseDecodeModel.makeOptionalNilValue(Payload.self) else {
                throw JSONRPCResponseDecodeError.wrongResponseType
            }
            return .regular(SwiftFulcrum.RPC.Response.Regular(id: id, result: nilProducer))
        }

        if let id {
            return .empty(id)
        }

        throw JSONRPCResponseDecodeError.cannotIdentifyResponseType(id)
    }
}
