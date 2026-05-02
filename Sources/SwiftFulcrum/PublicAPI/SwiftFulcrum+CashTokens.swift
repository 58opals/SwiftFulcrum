// SwiftFulcrum+CashTokens.swift

import Foundation

extension SwiftFulcrum {
    public enum CashTokens {}
}

extension SwiftFulcrum.CashTokens {
    public enum TokenFilter: String, Codable, Sendable {
        case include = "include_tokens"
        case exclude = "exclude_tokens"
        case only = "tokens_only"
    }
}

extension SwiftFulcrum.CashTokens {
    public struct TokenData: Codable, Sendable {
        public let amount: String
        public let category: String
        public let nft: NFT?

        public init(amount: String, category: String, nft: NFT?) {
            self.amount = amount
            self.category = category
            self.nft = nft
        }
    }
}

extension SwiftFulcrum.CashTokens.TokenData {
    public struct NFT: Codable, Sendable {
        public let capability: Capability
        public let commitment: String

        public init(capability: Capability, commitment: String) {
            self.capability = capability
            self.commitment = commitment
        }
    }
}

extension SwiftFulcrum.CashTokens.TokenData.NFT {
    public enum Capability: String, Codable, Sendable {
        case none
        case mutable
        case minting
    }
}
