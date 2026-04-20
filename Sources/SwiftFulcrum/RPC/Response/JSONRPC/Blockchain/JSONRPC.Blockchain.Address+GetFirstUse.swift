// JSONRPC.Blockchain.Address+GetFirstUse.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address {
    struct GetFirstUse: Decodable, Sendable {
        let block_hash: String
        let height: UInt
        let tx_hash: String
    }
}
