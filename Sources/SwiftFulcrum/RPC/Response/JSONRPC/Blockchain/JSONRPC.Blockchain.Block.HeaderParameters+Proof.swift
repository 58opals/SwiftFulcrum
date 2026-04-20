// JSONRPC.Blockchain.Block.HeaderParameters+Proof.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Block.HeaderParameters {
    struct Proof: Decodable, Sendable {
        let branch: [String]
        let header: String
        let root: String
    }
}
