// JSONRPCResponseDecodeModel.swift

import Foundation

enum JSONRPCResponseDecodeModel {
    struct IdentifierEnvelopeModel: Decodable, Sendable {
        let id: UUID?
        let method: String?
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
