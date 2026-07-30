// Response.Result.Blockchain.RPA.History+Transaction.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.RPA.History {
    public struct Transaction: Decodable, Sendable {
        /// The block height in which the transaction was confirmed.
        public let height: UInt

        /// The hexadecimal transaction hash.
        public let transactionHash: String

        init(
            from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.RPA.GetHistoryItem
        ) throws {
            guard let height = UInt(exactly: payloadModel.height) else {
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Expected RPA history transaction height to be non-negative"
                )
            }
            try SwiftFulcrum.Response.Blockchain.validateTransactionHash(
                payloadModel.tx_hash
            )

            self.height = height
            self.transactionHash = payloadModel.tx_hash
        }
    }
}
