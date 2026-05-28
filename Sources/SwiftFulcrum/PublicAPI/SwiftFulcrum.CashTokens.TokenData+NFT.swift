// SwiftFulcrum.CashTokens.TokenData+NFT.swift

extension SwiftFulcrum.CashTokens.TokenData {
    public struct NFT: Codable, Sendable {
        private static let maximumCommitmentByteCount = 40
        private static let maximumCommitmentHexCharacterCount = maximumCommitmentByteCount * 2

        public let capability: Capability
        public let commitment: String

        public init(capability: Capability, commitment: String) {
            self.capability = capability
            self.commitment = commitment
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let capability = try container.decode(Capability.self, forKey: .capability)
            let commitment = try container.decode(String.self, forKey: .commitment)
            try SwiftFulcrum.Response.Blockchain.validateHexString(commitment, description: "CashTokens NFT commitment")
            guard commitment.count <= Self.maximumCommitmentHexCharacterCount else {
                throw ResponseResultDecodeError.unexpectedFormat("Expected CashTokens NFT commitment to be at most 40 bytes")
            }
            self.capability = capability
            self.commitment = commitment
        }
    }
}
