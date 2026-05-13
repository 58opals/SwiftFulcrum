// Response.Result.Blockchain.Header+Get.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Header {
    public struct Get: Decodable, Sendable {
        public let height: UInt
        public let hex: String

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Header.Get(from: decoder)
            self.height = payloadModel.height
            self.hex = payloadModel.hex
        }
    }
}
