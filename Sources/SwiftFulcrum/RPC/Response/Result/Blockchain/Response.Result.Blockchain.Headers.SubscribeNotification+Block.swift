// Response.Result.Blockchain.Headers.SubscribeNotification+Block.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification {
    public struct Block: Decodable, Sendable {
        public let height: UInt
        public let hex: String

        init(height: UInt, hex: String) throws {
            try SwiftFulcrum.Response.Blockchain.validateBlockHeaderLength(hex)
            self.height = height
            self.hex = hex
        }

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Headers.Tip(from: decoder)
            try self.init(height: payloadModel.height, hex: payloadModel.hex)
        }
    }
}
