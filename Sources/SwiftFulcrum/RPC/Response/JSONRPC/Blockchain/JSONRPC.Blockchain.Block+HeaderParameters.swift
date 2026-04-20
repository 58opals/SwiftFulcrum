// JSONRPC.Blockchain.Block+HeaderParameters.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Block {
    typealias Header = HeaderParameters

    enum HeaderParameters: Decodable, Sendable {
        case raw(String)
        case proof(Proof)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let singleValue = try? container.decode(String.self) {
                self = .raw(singleValue)
                return
            }

            if let multipleValues = try? container.decode(Proof.self) {
                self = .proof(multipleValues)
                return
            }

            throw DecodingError.typeMismatch(
                HeaderParameters.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected String or Proof dictionary")
            )
        }
    }
}
