// Response.Result.Blockchain.Address+Mempool.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Address {
    public struct Mempool: Decodable, Sendable {
        public let transactions: [Transaction]

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetMempool(from: decoder)
            self.transactions = payloadModel.map(Transaction.init(from:))
        }
    }
}
