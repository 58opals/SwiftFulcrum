// Transaction+IDFromPos.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
    public struct IDFromPos: Decodable, Sendable {
        public let merkle: [String]
        public let transactionHash: String

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.IDFromPos(from: decoder)
            switch payloadModel {
            case .transactionHash(let transactionHash):
                self.merkle = []
                self.transactionHash = transactionHash
            case .merkleProof(let merkleProof):
                self.merkle = merkleProof.merkle
                self.transactionHash = merkleProof.tx_hash
            }
        }
    }
}
