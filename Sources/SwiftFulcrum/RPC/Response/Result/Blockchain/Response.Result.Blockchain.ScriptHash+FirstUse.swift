// Response.Result.Blockchain.ScriptHash+FirstUse.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.ScriptHash {
    public struct FirstUse: Decodable, Sendable {
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
            try SwiftFulcrum.Response.Blockchain.validateBlockHashLength(payloadModel.block_hash)
            try SwiftFulcrum.Response.Blockchain.validateTransactionHashLength(payloadModel.tx_hash)
            self.blockHash = payloadModel.block_hash
            self.height = payloadModel.height
            self.transactionHash = payloadModel.tx_hash
        }
    }
}

extension SwiftFulcrum.Response.Blockchain.ScriptHash.FirstUse: JSONRPCResponseDecodeModel.NilValue {
    static var nilValue: Self { .init(blockHash: nil, height: nil, transactionHash: nil) }
}
