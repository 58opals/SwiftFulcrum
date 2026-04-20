// JSONRPC.Blockchain.Address+GetHistoryItem.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address {
    struct GetHistoryItem: Decodable, Sendable {
        let height: Int
        let tx_hash: String
        let fee: UInt?
    }
}
