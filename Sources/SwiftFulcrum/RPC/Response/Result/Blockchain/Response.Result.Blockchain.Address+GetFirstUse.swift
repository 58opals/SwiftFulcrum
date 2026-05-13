// Response.Result.Blockchain.Address+GetFirstUse.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Address {
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
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetFirstUse(from: decoder)
            self.blockHash = payloadModel.block_hash
            self.height = payloadModel.height
            self.transactionHash = payloadModel.tx_hash
        }
    }
}

extension SwiftFulcrum.Response.Blockchain.Address.GetFirstUse: JSONRPCResponseDecodeModel.NilValue {
    static var nilValue: Self { .init(blockHash: nil, height: nil, transactionHash: nil) }
}
