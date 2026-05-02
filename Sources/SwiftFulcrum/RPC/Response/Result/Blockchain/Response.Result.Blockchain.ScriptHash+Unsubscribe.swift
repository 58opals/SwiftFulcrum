// Response.Blockchain.ScriptHash+Unsubscribe.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.ScriptHash {
    public struct Unsubscribe: Decodable, Sendable {
        public let isSuccess: Bool

        public init(from decoder: Decoder) throws {
            self.isSuccess = try Bool(from: decoder)
        }
    }
}
