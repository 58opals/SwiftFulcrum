// Response.Result.Blockchain.RPA+History.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.RPA {
    /// Confirmed RPA transactions in the server's protocol-defined blockchain order.
    public struct History: Decodable, Sendable {
        public let transactions: [Transaction]

        public init(from decoder: Decoder) throws {
            let payloadModel =
                try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.RPA.GetHistory(
                    from: decoder
                )
            self.transactions = try payloadModel.map(Transaction.init(from:))
        }
    }
}
