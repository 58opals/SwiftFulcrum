// Response.Blockchain.Headers+GetTip.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Headers {
    public struct GetTip: Decodable, Sendable {
        public let height: UInt
        public let hex: String

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Headers.GetTip(from: decoder)
            self.height = payloadModel.height
            self.hex = payloadModel.hex
        }
    }
}
