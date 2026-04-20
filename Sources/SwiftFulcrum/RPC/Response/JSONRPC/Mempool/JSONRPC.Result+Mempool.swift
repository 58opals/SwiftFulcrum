// JSONRPC.Result+Mempool.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result {
    struct Mempool {
        typealias FeeHistogram = [FlexibleNumber]
        typealias GetFeeHistogram = [FeeHistogram]
    }
}
