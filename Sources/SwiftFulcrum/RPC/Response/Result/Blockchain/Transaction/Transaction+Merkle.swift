// Transaction+Merkle.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction {
    public struct Merkle: Decodable, Sendable {
        public let merkle: [String]
        public let blockHeight: UInt
        public let position: UInt

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Merkle(from: decoder)
            try SwiftFulcrum.Response.Blockchain.validateMerkleHashLengths(payloadModel.merkle)
            self.merkle = payloadModel.merkle
            self.blockHeight = payloadModel.block_height
            self.position = payloadModel.pos
        }
    }
}
