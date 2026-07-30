// Response.Result.Blockchain.RPA.Mempool+Transaction.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.RPA.Mempool {
    public struct Transaction: Decodable, Sendable {
        /// `0` when every parent is confirmed, or `-1` when an unconfirmed parent exists.
        public let height: Int

        /// The hexadecimal transaction hash.
        public let transactionHash: String

        /// The transaction fee in satoshis.
        public let fee: UInt

        init(
            from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.RPA.GetMempoolItem
        ) throws {
            try SwiftFulcrum.Response.Blockchain.validateMempoolTransactionHeight(
                payloadModel.height
            )
            try SwiftFulcrum.Response.Blockchain.validateTransactionHash(
                payloadModel.tx_hash
            )

            self.height = payloadModel.height
            self.transactionHash = payloadModel.tx_hash
            self.fee = payloadModel.fee
        }
    }
}
