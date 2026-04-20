// JSONRPC.Blockchain.Address+GetMempoolItem.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address {
    struct GetMempoolItem: Decodable, Sendable {
        let height: Int
        let tx_hash: String
        let fee: UInt?
    }
}
