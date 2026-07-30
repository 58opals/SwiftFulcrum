// JSONRPC.Blockchain+RPA.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
    struct RPA {
        typealias GetHistory = [GetHistoryItem]
        typealias GetMempool = [GetMempoolItem]
    }
}
