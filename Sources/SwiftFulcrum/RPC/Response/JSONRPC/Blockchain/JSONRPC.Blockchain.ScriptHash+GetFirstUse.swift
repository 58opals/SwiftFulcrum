// JSONRPC.Blockchain.ScriptHash+GetFirstUse.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash {
    struct GetFirstUse: Decodable, Sendable {
        let block_hash: String
        let height: UInt
        let tx_hash: String
    }
}
