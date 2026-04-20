// JSONRPC.Blockchain.ScriptHash+GetHistoryItem.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash {
    struct GetHistoryItem: Decodable, Sendable {
        let height: Int
        let tx_hash: String
        let fee: UInt?
    }
}
