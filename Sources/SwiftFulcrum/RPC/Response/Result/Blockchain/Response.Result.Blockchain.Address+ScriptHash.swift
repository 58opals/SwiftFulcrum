// Response.Result.Blockchain.Address+ScriptHash.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Address {
    public struct ScriptHash: Decodable, Sendable {
        public let scriptHash: String

        public init(from decoder: Decoder) throws {
            let scriptHash = try String(from: decoder)
            try SwiftFulcrum.Response.Blockchain.validateScriptHash(scriptHash)
            self.scriptHash = scriptHash
        }
    }
}
