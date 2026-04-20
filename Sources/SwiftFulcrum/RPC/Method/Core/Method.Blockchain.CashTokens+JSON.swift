// Method.Blockchain.CashTokens+JSON.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain.CashTokens {
    public struct JSON: Codable, Sendable {
        public let amount: String
        public let category: String
        public let nft: NFT?
    }
}
