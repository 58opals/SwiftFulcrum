// JSONRPC.Blockchain.RPA+GetHistoryItem.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.RPA {
    struct GetHistoryItem: Decodable, Sendable {
        let height: Int
        let tx_hash: String
    }
}
