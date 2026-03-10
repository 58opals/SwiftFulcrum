// JSONRPC.Blockchain+Header.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
    struct Header {
        struct Get: Decodable, Sendable {
            let height: UInt
            let hex: String
        }
    }
}
