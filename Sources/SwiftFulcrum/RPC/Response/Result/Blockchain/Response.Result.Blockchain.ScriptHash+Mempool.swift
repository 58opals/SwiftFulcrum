// Response.Result.Blockchain.ScriptHash+Mempool.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.ScriptHash {
    public struct Mempool: Decodable, Sendable {
        public let transactions: [Transaction]

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetMempool(from: decoder)
            self.transactions = try payloadModel.map(Transaction.init(from:))
        }
    }
}
