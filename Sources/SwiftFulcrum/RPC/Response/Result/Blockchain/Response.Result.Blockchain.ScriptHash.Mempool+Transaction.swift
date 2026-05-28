// Response.Result.Blockchain.ScriptHash.Mempool+Transaction.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.ScriptHash.Mempool {
    public struct Transaction: Decodable, Sendable {
        public let height: Int
        public let transactionHash: String
        public let fee: UInt?

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetMempoolItem) throws {
            try SwiftFulcrum.Response.Blockchain.validateMempoolTransactionHeight(payloadModel.height)
            try SwiftFulcrum.Response.Blockchain.validateTransactionHash(payloadModel.tx_hash)
            self.height = payloadModel.height
            self.transactionHash = payloadModel.tx_hash
            self.fee = payloadModel.fee
        }
    }
}
