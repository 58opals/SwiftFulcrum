// Method.Blockchain+ScriptHash.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain {
    enum ScriptHash: Sendable {
        case getBalance(scripthash: String, tokenFilter: SwiftFulcrum.CashTokens.TokenFilter?)
        case getFirstUse(scripthash: String)
        case getHistory(scripthash: String, fromHeight: UInt?, toHeight: UInt?, shouldIncludeUnconfirmed: Bool)
        case getMempool(scripthash: String)
        case listUnspent(scripthash: String, tokenFilter: SwiftFulcrum.CashTokens.TokenFilter?)
        case subscribe(scripthash: String)
        case unsubscribe(scripthash: String)
    }
}
