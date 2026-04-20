// JSONRPC.Blockchain.Transaction+IDFromPosParameters.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction {
    enum IDFromPosParameters: Decodable, Sendable {
        case transactionHash(String)
        case merkleProof(MerkleProof)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let transactionHash = try? container.decode(String.self) {
                self = .transactionHash(transactionHash)
                return
            }

            if let merkleProof = try? container.decode(MerkleProof.self) {
                self = .merkleProof(merkleProof)
                return
            }

            throw DecodingError.typeMismatch(
                IDFromPosParameters.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected transaction hash string or merkle proof object"
                )
            )
        }
    }
}
