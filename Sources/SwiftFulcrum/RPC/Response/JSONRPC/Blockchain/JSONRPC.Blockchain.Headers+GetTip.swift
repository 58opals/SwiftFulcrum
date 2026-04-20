// JSONRPC.Blockchain.Headers+GetTip.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Headers {
    struct GetTip: Decodable, Sendable {
        let height: UInt
        let hex: String
    }
}
