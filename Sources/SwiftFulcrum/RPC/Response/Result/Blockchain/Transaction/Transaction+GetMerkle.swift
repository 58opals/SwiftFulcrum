// Transaction+GetMerkle.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction {
    public struct GetMerkle: Decodable, Sendable {
        public let merkle: [String]
        public let blockHeight: UInt
        public let position: UInt

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.GetMerkle(from: decoder)
            self.merkle = payloadModel.merkle
            self.blockHeight = payloadModel.block_height
            self.position = payloadModel.pos
        }
    }
}
