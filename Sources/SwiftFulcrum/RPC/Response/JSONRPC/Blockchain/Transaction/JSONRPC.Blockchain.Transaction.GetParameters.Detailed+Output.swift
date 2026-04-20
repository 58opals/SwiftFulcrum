// JSONRPC.Blockchain.Transaction.GetParameters.Detailed+Output.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.GetParameters.Detailed {
    struct Output: Decodable, Sendable {
        let n: UInt
        let scriptPubKey: ScriptPubKey
        let value: Double
    }
}
