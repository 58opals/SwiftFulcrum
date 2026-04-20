// Method.Blockchain.CashTokens.JSON.NFT+Capability.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON.NFT {
    public enum Capability: String, Codable, Sendable {
        case none
        case mutable
        case minting
    }
}
