// Response.Result.Blockchain.Block.Header+Proof.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Block.Header {
    public struct Proof: Decodable, Sendable {
        public let branch: [String]
        public let root: String
    }
}
