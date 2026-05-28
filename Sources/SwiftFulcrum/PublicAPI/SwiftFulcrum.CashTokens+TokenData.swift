// SwiftFulcrum.CashTokens+TokenData.swift

extension SwiftFulcrum.CashTokens {
    public struct TokenData: Codable, Sendable {
        private static let maximumFungibleTokenAmount = UInt64(Int64.max)

        public let amount: String
        public let category: String
        public let nft: NFT?

        public init(amount: String, category: String, nft: NFT?) {
            self.amount = amount
            self.category = category
            self.nft = nft
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let amount = try container.decode(String.self, forKey: .amount)
            let category = try container.decode(String.self, forKey: .category)
            try Self.validateAmount(amount)
            try SwiftFulcrum.Response.Blockchain.validateTransactionHash(category)
            self.amount = amount
            self.category = category
            self.nft = try container.decodeIfPresent(NFT.self, forKey: .nft)
        }

        private static func validateAmount(_ amount: String) throws {
            guard !amount.isEmpty,
                  amount.utf8.allSatisfy({ (48 ... 57).contains($0) }),
                  let parsedAmount = UInt64(amount),
                  parsedAmount <= maximumFungibleTokenAmount else {
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Expected CashTokens amount to be a non-negative decimal integer string"
                )
            }
        }
    }
}
