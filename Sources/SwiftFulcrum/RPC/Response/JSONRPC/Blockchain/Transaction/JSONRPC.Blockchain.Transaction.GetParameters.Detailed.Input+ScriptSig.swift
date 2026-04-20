// JSONRPC.Blockchain.Transaction.GetParameters.Detailed.Input+ScriptSig.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.GetParameters.Detailed.Input {
    struct ScriptSig: Decodable, Sendable {
        let asm: String
        let hex: String
    }
}
