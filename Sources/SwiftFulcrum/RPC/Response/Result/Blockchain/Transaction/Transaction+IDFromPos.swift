// Transaction+IDFromPos.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
    public struct IDFromPos: Decodable, Sendable {
        public let merkle: [String]
        public let transactionHash: String

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.IDFromPos(from: decoder)
            self.merkle = payloadModel.merkle
            self.transactionHash = payloadModel.tx_hash
        }
    }
}
