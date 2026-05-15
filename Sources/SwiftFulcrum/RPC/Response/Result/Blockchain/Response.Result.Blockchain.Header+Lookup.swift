// Response.Result.Blockchain.Header+Lookup.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Header {
    public struct Lookup: Decodable, Sendable {
        public let height: UInt
        public let hex: String

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Header.Lookup(from: decoder)
            try SwiftFulcrum.Response.Blockchain.validateBlockHeaderLength(payloadModel.hex)
            self.height = payloadModel.height
            self.hex = payloadModel.hex
        }
    }
}
