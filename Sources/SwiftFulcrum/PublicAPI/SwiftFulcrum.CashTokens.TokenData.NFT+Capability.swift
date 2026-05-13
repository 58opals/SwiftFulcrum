// SwiftFulcrum.CashTokens.TokenData.NFT+Capability.swift

extension SwiftFulcrum.CashTokens.TokenData.NFT {
    public enum Capability: String, Codable, Sendable {
        case none
        case mutable
        case minting
    }
}
