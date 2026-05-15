// Response.Result.Blockchain.Headers+Tip.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Headers {
    public struct Tip: Decodable, Sendable {
        public let height: UInt
        public let hex: String

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Headers.Tip(from: decoder)
            try SwiftFulcrum.Response.Blockchain.validateBlockHeaderLength(payloadModel.hex)
            self.height = payloadModel.height
            self.hex = payloadModel.hex
        }
    }
}
