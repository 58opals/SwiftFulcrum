// JSONRPC.Blockchain.Address+ListUnspentItem.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address {
    struct ListUnspentItem: Decodable, Sendable {
        let height: UInt
        let token_data: SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON?
        let tx_hash: String
        let tx_pos: UInt
        let value: UInt64
    }
}
