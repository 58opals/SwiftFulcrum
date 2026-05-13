// JSONRPC.Blockchain.UTXO+Info.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.UTXO {
    struct Info: Decodable, Sendable {
        let confirmed_height: UInt?
        let scripthash: String
        let value: UInt
        let token_data: SwiftFulcrum.CashTokens.TokenData?
    }
}
