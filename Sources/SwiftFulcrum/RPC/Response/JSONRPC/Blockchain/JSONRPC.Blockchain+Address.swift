// JSONRPC.Blockchain+Address.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
    struct Address {
        typealias GetHistory = [GetHistoryItem]
        typealias GetMempool = [GetMempoolItem]
        typealias GetScriptHash = String

        typealias ListUnspent = [ListUnspentItem]
        typealias Subscribe = SubscribeParameters
        typealias Unsubscribe = Bool
    }
}
