// Transaction+ConfirmedBlockHash.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction {
    public struct ConfirmedBlockHash: Decodable, Sendable {
        public let blockHash: String
        public let blockHeader: String?
        public let blockHeight: UInt

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.GetConfirmedBlockHash(from: decoder)
            try SwiftFulcrum.Response.Blockchain.validateBlockHash(payloadModel.block_hash)
            if let blockHeader = payloadModel.block_header {
                try SwiftFulcrum.Response.Blockchain.validateBlockHeader(blockHeader)
            }
            self.blockHash = payloadModel.block_hash
            self.blockHeader = payloadModel.block_header
            self.blockHeight = payloadModel.block_height
        }
    }
}
