// Response.Result.Blockchain.Headers+Subscribe.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Headers {
    public struct Subscribe: Decodable, Sendable {
        public let height: UInt
        public let hex: String

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Headers.Subscribe(from: decoder)
            switch payloadModel {
            case .topHeader(let tip):
                try SwiftFulcrum.Response.Blockchain.validateBlockHeader(tip.hex)
                self.height = tip.height
                self.hex = tip.hex
            case .newHeader(let batch) where batch.count == 1:
                try SwiftFulcrum.Response.Blockchain.validateBlockHeader(batch[0].hex)
                self.height = batch[0].height
                self.hex = batch[0].hex
            case .newHeader(let batch):
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Expected single top header; received batch with \(batch.count) headers"
                )
            }
        }
    }
}
