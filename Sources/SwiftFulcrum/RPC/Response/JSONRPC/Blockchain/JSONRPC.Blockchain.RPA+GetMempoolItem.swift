// JSONRPC.Blockchain.RPA+GetMempoolItem.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.RPA {
    struct GetMempoolItem: Decodable, Sendable {
        let height: Int
        let tx_hash: String
        let fee: UInt
    }
}
