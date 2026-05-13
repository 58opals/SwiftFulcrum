// Response.Result.Blockchain.Address+History.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Address {
    public struct History: Decodable, Sendable {
        public let transactions: [Transaction]

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetHistory(from: decoder)
            self.transactions = payloadModel.map(Transaction.init(from:))
        }
    }
}
