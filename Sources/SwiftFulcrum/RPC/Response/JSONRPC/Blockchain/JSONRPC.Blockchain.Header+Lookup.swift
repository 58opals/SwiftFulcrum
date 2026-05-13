// JSONRPC.Blockchain.Header+Lookup.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Header {
    struct Lookup: Decodable, Sendable {
        let height: UInt
        let hex: String
    }
}
