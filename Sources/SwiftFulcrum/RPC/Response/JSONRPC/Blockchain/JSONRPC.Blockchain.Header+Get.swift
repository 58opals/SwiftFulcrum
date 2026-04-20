// JSONRPC.Blockchain.Header+Get.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Header {
    struct Get: Decodable, Sendable {
        let height: UInt
        let hex: String
    }
}
