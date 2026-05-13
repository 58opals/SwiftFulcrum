// JSONRPCResponseDecodeModel+IdentifierEnvelopeModel.swift

import Foundation

extension JSONRPCResponseDecodeModel {
    struct IdentifierEnvelopeModel: Decodable, Sendable {
        let id: UUID?
        let method: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeyModel.self)
            let idKey = CodingKeyModel("id")
            let methodKey = CodingKeyModel("method")

            try JSONRPCResponseDecodeModel.validateVersion(in: container)
            self.id = try container.decodeIfPresent(UUID.self, forKey: idKey)
            self.method = try container.decodeIfPresent(String.self, forKey: methodKey)
        }
    }
}
