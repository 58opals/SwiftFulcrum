// Transaction.DSProof+List.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.DSProof {
    public struct List: Decodable, Sendable {
        public let transactionHashes: [String]

        public init(from decoder: Decoder) throws {
            let transactionHashes = try [String](from: decoder)
            try SwiftFulcrum.Response.Blockchain.validateTransactionHashes(
                transactionHashes,
                description: "DSProof transaction hash"
            )
            self.transactionHashes = transactionHashes
        }
    }
}
