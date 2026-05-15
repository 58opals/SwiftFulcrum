// Transaction+IDFromPos.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction {
    public struct IDFromPos: Decodable, Sendable {
        public let merkle: [String]
        public let transactionHash: String

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.IDFromPos(from: decoder)
            switch payloadModel {
            case .transactionHash(let transactionHash):
                try SwiftFulcrum.Response.Blockchain.validateTransactionHashLength(transactionHash)
                self.merkle = []
                self.transactionHash = transactionHash
            case .merkleProof(let merkleProof):
                try SwiftFulcrum.Response.Blockchain.validateTransactionHashLength(merkleProof.tx_hash)
                try SwiftFulcrum.Response.Blockchain.validateMerkleHashLengths(merkleProof.merkle)
                self.merkle = merkleProof.merkle
                self.transactionHash = merkleProof.tx_hash
            }
        }
    }
}
