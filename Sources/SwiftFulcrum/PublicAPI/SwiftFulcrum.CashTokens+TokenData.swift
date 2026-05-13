// SwiftFulcrum.CashTokens+TokenData.swift

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
