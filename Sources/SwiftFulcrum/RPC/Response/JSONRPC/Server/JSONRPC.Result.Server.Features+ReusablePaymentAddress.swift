// JSONRPC.Result.Server.Features+ReusablePaymentAddress.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features {
    struct ReusablePaymentAddress: Decodable, Sendable {
        let history_block_limit: Int?
        let max_history: Int?
        let prefix_bits: Int?
        let prefix_bits_min: Int?
        let starting_height: Int?
    }
}
