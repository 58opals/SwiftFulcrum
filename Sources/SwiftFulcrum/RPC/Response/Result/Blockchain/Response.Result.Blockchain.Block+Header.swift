// Response.Result.Blockchain.Block+Header.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Block {
    public struct Header: Decodable, Sendable {
        public let hex: String
        public let proof: Proof?

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Block.Header(from: decoder)
            switch payloadModel {
            case .raw(let raw):
                try Self.validateHeaderLength(raw)
                self.hex = raw
                self.proof = nil
            case .proof(let proof):
                try Self.validateHeaderLength(proof.header)
                self.hex = proof.header
                self.proof = Proof(branch: proof.branch, root: proof.root)
            }
        }

        private static func validateHeaderLength(_ header: String) throws {
            let headerCharacterLength = 160
            guard header.count == headerCharacterLength else {
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Expected block header to be exactly \(headerCharacterLength) hex characters"
                )
            }
        }
    }
}
