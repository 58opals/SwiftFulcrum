// Transaction.Verbose.Input+ScriptSig.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.Verbose.Input {
    public struct ScriptSig: Decodable, Sendable {
        public let assemblyScriptLanguage: String
        public let hex: String

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Input.ScriptSig) {
            self.assemblyScriptLanguage = payloadModel.asm
            self.hex = payloadModel.hex
        }
    }
}
