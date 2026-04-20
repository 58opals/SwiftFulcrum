// JSONRPC.Blockchain.Address+GetBalance.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address {
    struct GetBalance: Decodable, Sendable {
        let confirmed: UInt64
        let unconfirmed: Int64
    }
}
