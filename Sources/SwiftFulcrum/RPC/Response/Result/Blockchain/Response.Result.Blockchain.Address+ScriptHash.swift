// Response.Result.Blockchain.Address+ScriptHash.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Address {
    public struct ScriptHash: Decodable, Sendable {
        public let scriptHash: String

        public init(from decoder: Decoder) throws {
            self.scriptHash = try String(from: decoder)
        }
    }
}
