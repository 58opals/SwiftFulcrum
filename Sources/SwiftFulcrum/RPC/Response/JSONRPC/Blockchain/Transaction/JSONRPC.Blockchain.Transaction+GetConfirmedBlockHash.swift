// JSONRPC.Blockchain.Transaction+GetConfirmedBlockHash.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction {
    struct GetConfirmedBlockHash: Decodable, Sendable {
        let block_hash: String
        let block_header: String?
        let block_height: UInt
    }
}
