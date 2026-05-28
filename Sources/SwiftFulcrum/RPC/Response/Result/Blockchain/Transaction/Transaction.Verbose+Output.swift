// Transaction.Verbose+Output.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.Verbose {
    public struct Output: Decodable, Sendable {
        public let index: UInt
        public let scriptPubKey: ScriptPubKey
        public let value: Double

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Output) throws {
            guard payloadModel.value.isFinite, payloadModel.value >= 0 else {
                throw ResponseResultDecodeError.unexpectedFormat("Invalid transaction output value: \(payloadModel.value)")
            }
            self.index = payloadModel.n
            self.scriptPubKey = try ScriptPubKey(from: payloadModel.scriptPubKey)
            self.value = payloadModel.value
        }
    }
}
