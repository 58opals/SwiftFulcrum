// JSONRPCResponseDecodeModel+ErasedResponseEnvelope.swift

import Foundation

extension JSONRPCResponseDecodeModel {
    struct ErasedResponseEnvelope: Decodable, Sendable {
        let id: UUID?
        let error: SwiftFulcrum.RPC.Response.Error.Result?
        let hasResult: Bool
        let hasError: Bool
        let hasMethod: Bool
        let hasParams: Bool

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKey.self)
            let idKey = CodingKey("id")
            let resultKey = CodingKey("result")
            let errorKey = CodingKey("error")
            let methodKey = CodingKey("method")
            let paramsKey = CodingKey("params")

            try JSONRPCResponseDecodeModel.validateVersion(in: container)
            self.id = try container.decodeIfPresent(UUID.self, forKey: idKey)
            self.error = try container.decodeIfPresent(SwiftFulcrum.RPC.Response.Error.Result.self, forKey: errorKey)
            self.hasResult = container.contains(resultKey)
            self.hasError = container.contains(errorKey)
            self.hasMethod = container.contains(methodKey)
            self.hasParams = container.contains(paramsKey)
        }
    }
}
