// Response.Result.Blockchain.Address.Mempool+Transaction.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Address.Mempool {
    public struct Transaction: Decodable, Sendable {
        public let height: Int
        public let transactionHash: String
        public let fee: UInt?

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetMempoolItem) {
            self.height = payloadModel.height
            self.transactionHash = payloadModel.tx_hash
            self.fee = payloadModel.fee
        }
    }
}
