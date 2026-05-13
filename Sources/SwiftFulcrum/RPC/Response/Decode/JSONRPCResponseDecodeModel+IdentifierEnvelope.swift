// JSONRPCResponseDecodeModel+IdentifierEnvelope.swift

import Foundation

extension JSONRPCResponseDecodeModel {
    struct IdentifierEnvelope: Decodable, Sendable {
        let id: UUID?
        let method: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKey.self)
            let idKey = CodingKey("id")
            let methodKey = CodingKey("method")

            try JSONRPCResponseDecodeModel.validateVersion(in: container)
            self.id = try container.decodeIfPresent(UUID.self, forKey: idKey)
            self.method = try container.decodeIfPresent(String.self, forKey: methodKey)
        }
    }
}
