// JSONRPC.Blockchain.Transaction.GetParameters+Detailed.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.GetParameters {
    struct Detailed: Decodable, Sendable {
        let blockhash: String?
        let blocktime: UInt?
        let confirmations: UInt?
        let hash: String
        let hex: String
        let locktime: UInt
        let size: UInt
        let time: UInt?
        let txid: String
        let version: UInt
        let vin: [Input]
        let vout: [Output]
    }
}
