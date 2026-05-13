// JSONRPC.Blockchain.Headers+Tip.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Headers {
    struct Tip: Decodable, Sendable {
        let height: UInt
        let hex: String
    }
}
