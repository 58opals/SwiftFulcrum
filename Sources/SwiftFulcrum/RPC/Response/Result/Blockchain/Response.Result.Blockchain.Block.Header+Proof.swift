// Response.Result.Blockchain.Block.Header+Proof.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Block.Header {
    public struct Proof: Decodable, Sendable {
        public let branch: [String]
        public let root: String

        init(branch: [String], root: String) throws {
            try SwiftFulcrum.Response.Blockchain.validateMerkleHashes(branch)
            try SwiftFulcrum.Response.Blockchain.validateMerkleRoot(root)
            self.branch = branch
            self.root = root
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JSONRPCResponseDecodeModel.CodingKey.self)
            let branch = try container.decode([String].self, forKey: .init("branch"))
            let root = try container.decode(String.self, forKey: .init("root"))
            try self.init(branch: branch, root: root)
        }
    }
}
