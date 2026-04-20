// JSONRPC.Blockchain.Transaction+GetMerkle.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction {
    struct GetMerkle: Decodable, Sendable {
        let merkle: [String]
        let block_height: UInt
        let pos: UInt
    }
}
