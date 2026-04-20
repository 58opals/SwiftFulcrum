// JSONRPC.Blockchain.Transaction.GetParameters.Detailed.Output+ScriptPubKey.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.GetParameters.Detailed.Output {
    struct ScriptPubKey: Decodable, Sendable {
        let address: String?
        let addresses: [String]?
        let asm: String
        let hex: String
        let reqSigs: UInt?
        let type: String
    }
}
