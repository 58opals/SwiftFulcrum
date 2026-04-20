// JSONRPC.Blockchain.Transaction+GetParameters.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction {
    enum GetParameters: Decodable, Sendable {
        case raw(String)
        case detailed(Detailed)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let singleValue = try? container.decode(String.self) {
                self = .raw(singleValue)
                return
            }

            if let multipleValues = try? container.decode(Detailed.self) {
                self = .detailed(multipleValues)
                return
            }

            throw DecodingError.typeMismatch(
                GetParameters.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected String or Detailed")
            )
        }
    }
}
