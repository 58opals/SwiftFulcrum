// Response.Result.Blockchain.Headers+Tip.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Headers {
    public struct Tip: Decodable, Sendable {
        public let height: UInt
        public let hex: String

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Headers.Tip(from: decoder)
            try Self.validateHeaderLength(payloadModel.hex)
            self.height = payloadModel.height
            self.hex = payloadModel.hex
        }

        private static func validateHeaderLength(_ header: String) throws {
            let headerCharacterLength = 160
            guard header.count == headerCharacterLength else {
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Expected block header to be exactly \(headerCharacterLength) hex characters"
                )
            }
        }
    }
}
