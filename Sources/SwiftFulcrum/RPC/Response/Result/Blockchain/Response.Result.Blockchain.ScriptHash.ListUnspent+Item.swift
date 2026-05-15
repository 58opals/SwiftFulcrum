// Response.Result.Blockchain.ScriptHash.ListUnspent+Item.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.ScriptHash.ListUnspent {
    public struct Item: Decodable, Sendable {
        public let height: UInt
        public let tokenData: SwiftFulcrum.CashTokens.TokenData?
        public let transactionHash: String
        public let transactionPosition: UInt
        public let value: UInt64

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.ListUnspentItem) throws {
            try SwiftFulcrum.Response.Blockchain.validateTransactionHashLength(payloadModel.tx_hash)
            self.height = payloadModel.height
            self.tokenData = payloadModel.token_data
            self.transactionHash = payloadModel.tx_hash
            self.transactionPosition = payloadModel.tx_pos
            self.value = payloadModel.value
        }
    }
}
