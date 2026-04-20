// Method.Blockchain.CashTokens.JSON+NFT.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON {
    public struct NFT: Codable, Sendable {
        public let capability: Capability
        public let commitment: String
    }
}
