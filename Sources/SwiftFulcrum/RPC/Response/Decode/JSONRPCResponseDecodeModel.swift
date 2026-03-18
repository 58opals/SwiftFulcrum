// JSONRPCResponseDecodeModel.swift

import Foundation

enum JSONRPCResponseDecodeModel {
    struct IdentifierEnvelopeModel: Decodable, Sendable {
        let id: UUID?
        let method: String?
    }

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

    struct CodingKeyModel: CodingKey, Hashable, Sendable {
        let stringValue: String
        let intValue: Int? = nil

        init(_ stringValue: String) {
            self.stringValue = stringValue
        }

        init?(stringValue: String) {
            self.init(stringValue)
        }

        init?(intValue: Int) {
            return nil
        }
    }

    protocol NilValueModel {
        static var nilValue: Self { get }
    }

    static func makeOptionalNilValue<Payload>(_ type: Payload.Type) -> Payload? {
        guard let optionalType = Payload.self as? NilValueModel.Type else { return nil }
        return optionalType.nilValue as? Payload
    }
}

extension Optional: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { nil }
}
