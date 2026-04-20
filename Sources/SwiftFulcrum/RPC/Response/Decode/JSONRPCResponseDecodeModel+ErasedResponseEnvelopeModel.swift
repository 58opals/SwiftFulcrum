// JSONRPCResponseDecodeModel+ErasedResponseEnvelopeModel.swift

import Foundation

extension JSONRPCResponseDecodeModel {
    struct ErasedResponseEnvelopeModel: Decodable, Sendable {
        let id: UUID?
        let error: SwiftFulcrum.RPC.Response.Error.Result?
        private let hasResultKey: Bool
        var hasResult: Bool { hasResultKey }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeyModel.self)
            let idKey = CodingKeyModel("id")
            let resultKey = CodingKeyModel("result")
            let errorKey = CodingKeyModel("error")

            self.id = try container.decodeIfPresent(UUID.self, forKey: idKey)
            self.error = try container.decodeIfPresent(SwiftFulcrum.RPC.Response.Error.Result.self, forKey: errorKey)
            self.hasResultKey = container.contains(resultKey)
        }
    }
}
