// Method.Blockchain+Address.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain {
    public enum Address: Sendable {
        public typealias fromHeight = UInt
        public typealias toHeight = UInt
        public typealias shouldIncludeUnconfirmed = Bool

        case getBalance(address: String, tokenFilter: CashTokens.TokenFilter?)
        case getFirstUse(address: String)
        case getHistory(address: String, fromHeight: UInt?, toHeight: UInt?, shouldIncludeUnconfirmed: Bool)
        case getMempool(address: String)
        case getScriptHash(address: String)
        case listUnspent(address: String, tokenFilter: CashTokens.TokenFilter?)
        case subscribe(address: String)
        case unsubscribe(address: String)
    }
}
