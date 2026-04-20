// JSONRPCResponseDecodeModel.swift

import Foundation

enum JSONRPCResponseDecodeModel {
    static func makeOptionalNilValue<Payload>(_ type: Payload.Type) -> Payload? {
        guard let optionalType = Payload.self as? NilValueModel.Type else { return nil }
        return optionalType.nilValue as? Payload
    }
}
