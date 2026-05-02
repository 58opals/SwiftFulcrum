// Transaction.Get+Input.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.Get {
    public struct Input: Decodable, Sendable {
        public let coinbase: String?
        public let scriptSig: ScriptSig?
        public let sequence: UInt
        public let transactionID: String?
        public let indexNumberOfPreviousTransactionOutput: UInt?

        public var isCoinbase: Bool { coinbase != nil }

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Input) {
            self.coinbase = payloadModel.coinbase
            self.scriptSig = payloadModel.scriptSig.map(ScriptSig.init(from:))
            self.sequence = payloadModel.sequence
            self.transactionID = payloadModel.txid
            self.indexNumberOfPreviousTransactionOutput = payloadModel.vout
        }
    }
}
