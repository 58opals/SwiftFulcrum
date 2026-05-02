// Method.Blockchain+Address.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain {
    enum Address: Sendable {
        typealias fromHeight = UInt
        typealias toHeight = UInt
        typealias shouldIncludeUnconfirmed = Bool

        case getBalance(address: String, tokenFilter: SwiftFulcrum.CashTokens.TokenFilter?)
        case getFirstUse(address: String)
        case getHistory(address: String, fromHeight: UInt?, toHeight: UInt?, shouldIncludeUnconfirmed: Bool)
        case getMempool(address: String)
        case getScriptHash(address: String)
        case listUnspent(address: String, tokenFilter: SwiftFulcrum.CashTokens.TokenFilter?)
        case subscribe(address: String)
        case unsubscribe(address: String)
    }
}
