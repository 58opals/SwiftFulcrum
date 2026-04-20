// JSONRPC.Blockchain+Transaction.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
    struct Transaction {
        typealias Broadcast = String
        typealias Get = GetParameters
        typealias GetHeight = UInt
        typealias IDFromPos = IDFromPosParameters
        typealias Subscribe = SubscribeParameters
        typealias Unsubscribe = Bool
    }
}
