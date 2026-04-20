// JSONRPC.Blockchain.Transaction+DSProof.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction {
    struct DSProof {
        typealias List = [String]
        typealias Subscribe = SubscribeParameters
        typealias Unsubscribe = Bool
    }
}
