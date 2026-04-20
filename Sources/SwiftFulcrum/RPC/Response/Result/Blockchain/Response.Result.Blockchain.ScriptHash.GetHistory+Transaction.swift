// Response.Result.Blockchain.ScriptHash.GetHistory+Transaction.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.GetHistory {
    public struct Transaction: Decodable, Sendable {
        public let height: Int
        public let transactionHash: String
        public let fee: UInt?

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetHistoryItem) {
            self.height = payloadModel.height
            self.transactionHash = payloadModel.tx_hash
            self.fee = payloadModel.fee
        }
    }
}
