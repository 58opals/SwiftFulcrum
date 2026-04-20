// JSONRPCResponseDecodeModel+IdentifierEnvelopeModel.swift

import Foundation

extension JSONRPCResponseDecodeModel {
    struct IdentifierEnvelopeModel: Decodable, Sendable {
        let id: UUID?
        let method: String?
    }
}
