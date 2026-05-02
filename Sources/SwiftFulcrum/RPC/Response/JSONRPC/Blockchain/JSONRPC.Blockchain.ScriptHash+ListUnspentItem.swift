// JSONRPC.Blockchain.ScriptHash+ListUnspentItem.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash {
    struct ListUnspentItem: Decodable, Sendable {
        let height: UInt
        let token_data: SwiftFulcrum.CashTokens.TokenData?
        let tx_hash: String
        let tx_pos: UInt
        let value: UInt64
    }
}
