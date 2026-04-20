// Response.Result.Blockchain.Headers+Unsubscribe.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Headers {
    public struct Unsubscribe: Decodable, Sendable {
        public let isSuccess: Bool

        public init(from decoder: Decoder) throws {
            self.isSuccess = try Bool(from: decoder)
        }
    }
}
