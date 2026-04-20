// JSONRPC.Blockchain.ScriptHash+GetBalance.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash {
    struct GetBalance: Decodable, Sendable {
        let confirmed: UInt64
        let unconfirmed: Int64
    }
}
