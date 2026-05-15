// Response.Result.Blockchain.ScriptHash.History+Transaction.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.ScriptHash.History {
    public struct Transaction: Decodable, Sendable {
        public let height: Int
        public let transactionHash: String
        public let fee: UInt?

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetHistoryItem) throws {
            try SwiftFulcrum.Response.Blockchain.validateTransactionHashLength(payloadModel.tx_hash)
            self.height = payloadModel.height
            self.transactionHash = payloadModel.tx_hash
            self.fee = payloadModel.fee
        }
    }
}
