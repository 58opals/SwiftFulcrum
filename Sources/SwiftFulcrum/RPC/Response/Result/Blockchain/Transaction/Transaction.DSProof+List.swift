// Transaction.DSProof+List.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.DSProof {
    public struct List: Decodable, Sendable {
        public let transactionHashes: [String]

        public init(from decoder: Decoder) throws {
            self.transactionHashes = try [String](from: decoder)
        }
    }
}
