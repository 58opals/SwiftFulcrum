// JSONRPC.Blockchain+UTXO.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
    struct UTXO {
        struct GetInfo: Decodable, Sendable {
            let confirmed_height: UInt?
            let scripthash: String
            let value: UInt
            let token_data: SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON?
        }
    }
}
