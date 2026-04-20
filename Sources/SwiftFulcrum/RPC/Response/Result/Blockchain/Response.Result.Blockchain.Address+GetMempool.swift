// Response.Result.Blockchain.Address+GetMempool.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Address {
    public struct GetMempool: Decodable, Sendable {
        public let transactions: [Transaction]

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetMempool(from: decoder)
            self.transactions = payloadModel.map(Transaction.init(from:))
        }
    }
}
