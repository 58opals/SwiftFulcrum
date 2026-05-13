// JSONRPCResponseDecodeModel+ErasedResponseEnvelope.swift

import Foundation

extension JSONRPCResponseDecodeModel {
    struct ErasedResponseEnvelope: Decodable, Sendable {
        let id: UUID?
        let error: SwiftFulcrum.RPC.Response.Error.Result?
        private let hasResultKey: Bool
        private let hasErrorKey: Bool
        private let hasMethodKey: Bool
        private let hasParamsKey: Bool
        var hasResult: Bool { hasResultKey }
        var hasError: Bool { hasErrorKey }
        var hasMethod: Bool { hasMethodKey }
        var hasParams: Bool { hasParamsKey }

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
            self.hasResultKey = container.contains(resultKey)
            self.hasErrorKey = container.contains(errorKey)
            self.hasMethodKey = container.contains(methodKey)
            self.hasParamsKey = container.contains(paramsKey)
        }
    }
}
