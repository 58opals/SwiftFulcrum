// JSONRPC.Blockchain.Transaction.GetParameters.Detailed+Input.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.GetParameters.Detailed {
    struct Input: Decodable, Sendable {
        let coinbase: String?
        let scriptSig: ScriptSig?
        let sequence: UInt
        let txid: String?
        let vout: UInt?
    }
}
