// Transaction.Get+Output.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.Get {
    public struct Output: Decodable, Sendable {
        public let index: UInt
        public let scriptPubKey: ScriptPubKey
        public let value: Double

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Output) {
            self.index = payloadModel.n
            self.scriptPubKey = ScriptPubKey(from: payloadModel.scriptPubKey)
            self.value = payloadModel.value
        }
    }
}
