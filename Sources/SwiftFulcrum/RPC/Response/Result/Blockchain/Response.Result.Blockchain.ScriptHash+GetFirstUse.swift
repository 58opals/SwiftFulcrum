// Response.Result.Blockchain.ScriptHash+GetFirstUse.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash {
    public struct GetFirstUse: Decodable, Sendable {
        public let blockHash: String?
        public let height: UInt?
        public let transactionHash: String?
        public var isFound: Bool { blockHash != nil }

        init(blockHash: String?, height: UInt?, transactionHash: String?) {
            self.blockHash = blockHash
            self.height = height
            self.transactionHash = transactionHash
        }

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetFirstUse(from: decoder)
            self.blockHash = payloadModel.block_hash
            self.height = payloadModel.height
            self.transactionHash = payloadModel.tx_hash
        }
    }
}

extension SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.GetFirstUse: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { .init(blockHash: nil, height: nil, transactionHash: nil) }
}
