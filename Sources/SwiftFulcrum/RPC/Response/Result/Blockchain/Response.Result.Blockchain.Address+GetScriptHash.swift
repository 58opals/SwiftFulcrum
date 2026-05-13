// Response.Result.Blockchain.Address+GetScriptHash.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Address {
    public struct GetScriptHash: Decodable, Sendable {
        public let scriptHash: String

        public init(from decoder: Decoder) throws {
            self.scriptHash = try String(from: decoder)
        }
    }
}
