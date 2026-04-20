// JSONRPC.Blockchain.Transaction.DSProof.Get+Outpoint.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get {
    struct Outpoint: Decodable, Sendable {
        let txid: String
        let vout: UInt
    }
}
