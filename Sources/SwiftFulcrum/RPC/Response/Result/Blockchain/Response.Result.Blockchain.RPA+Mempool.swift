// Response.Result.Blockchain.RPA+Mempool.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.RPA {
    /// Unconfirmed RPA transactions in canonical Electrum Cash protocol order.
    public struct Mempool: Decodable, Sendable {
        public let transactions: [Transaction]

        public init(from decoder: Decoder) throws {
            let payloadModel =
                try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.RPA.GetMempool(
                    from: decoder
                )
            self.transactions = try payloadModel.map(Transaction.init(from:))
        }
    }
}
