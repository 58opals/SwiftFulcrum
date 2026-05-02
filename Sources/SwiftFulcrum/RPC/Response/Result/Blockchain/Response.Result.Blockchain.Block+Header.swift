// Response.Blockchain.Block+Header.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Block {
    public struct Header: Decodable, Sendable {
        public let hex: String
        public let proof: Proof?

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Block.Header(from: decoder)
            switch payloadModel {
            case .raw(let raw):
                self.hex = raw
                self.proof = nil
            case .proof(let proof):
                self.hex = proof.header
                self.proof = Proof(branch: proof.branch, root: proof.root)
            }
        }
    }
}
