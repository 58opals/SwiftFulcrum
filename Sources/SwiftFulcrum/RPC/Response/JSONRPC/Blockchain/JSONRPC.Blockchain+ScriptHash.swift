// JSONRPC.Blockchain+ScriptHash.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
    struct ScriptHash {
        typealias GetHistory = [GetHistoryItem]
        typealias GetMempool = [GetMempoolItem]
        typealias ListUnspent = [ListUnspentItem]
        typealias Subscribe = SubscribeParameters
        typealias Unsubscribe = Bool
    }
}
