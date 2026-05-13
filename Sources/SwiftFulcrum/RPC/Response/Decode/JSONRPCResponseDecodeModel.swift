// JSONRPCResponseDecodeModel.swift

import Foundation

enum JSONRPCResponseDecodeModel {
    static func validateVersion(in container: KeyedDecodingContainer<CodingKeyModel>) throws {
        let jsonrpcKey = CodingKeyModel("jsonrpc")
        let jsonrpc = try container.decode(String.self, forKey: jsonrpcKey)
        guard jsonrpc == "2.0" else {
            throw DecodingError.dataCorruptedError(
                forKey: jsonrpcKey,
                in: container,
                debugDescription: "JSON-RPC version must be 2.0."
            )
        }
    }

    static func makeOptionalNilValue<Payload>(_ type: Payload.Type) -> Payload? {
        guard let optionalType = Payload.self as? NilValue.Type else { return nil }
        return optionalType.nilValue as? Payload
    }
}
