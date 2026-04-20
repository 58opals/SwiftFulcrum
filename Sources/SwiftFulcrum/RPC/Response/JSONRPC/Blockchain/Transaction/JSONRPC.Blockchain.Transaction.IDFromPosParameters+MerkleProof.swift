// JSONRPC.Blockchain.Transaction.IDFromPosParameters+MerkleProof.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.IDFromPosParameters {
    struct MerkleProof: Decodable, Sendable {
        let merkle: [String]
        let tx_hash: String
    }
}
