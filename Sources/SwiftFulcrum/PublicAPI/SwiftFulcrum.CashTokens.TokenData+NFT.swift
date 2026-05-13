// SwiftFulcrum.CashTokens.TokenData+NFT.swift

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
