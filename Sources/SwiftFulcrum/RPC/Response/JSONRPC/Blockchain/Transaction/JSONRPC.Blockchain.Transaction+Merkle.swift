// JSONRPC.Blockchain.Transaction+Merkle.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction {
    struct Merkle: Decodable, Sendable {
        let merkle: [String]
        let block_height: UInt
        let pos: UInt
    }
}
