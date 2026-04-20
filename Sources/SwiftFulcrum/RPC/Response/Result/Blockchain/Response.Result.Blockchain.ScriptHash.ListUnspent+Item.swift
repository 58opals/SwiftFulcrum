// Response.Result.Blockchain.ScriptHash.ListUnspent+Item.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.ListUnspent {
    public struct Item: Decodable, Sendable {
        public let height: UInt
        public let tokenData: SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON?
        public let transactionHash: String
        public let transactionPosition: UInt
        public let value: UInt64

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.ListUnspentItem) {
            self.height = payloadModel.height
            self.tokenData = payloadModel.token_data
            self.transactionHash = payloadModel.tx_hash
            self.transactionPosition = payloadModel.tx_pos
            self.value = payloadModel.value
        }
    }
}
