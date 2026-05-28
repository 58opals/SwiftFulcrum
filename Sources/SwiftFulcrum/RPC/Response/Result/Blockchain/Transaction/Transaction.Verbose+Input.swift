// Transaction.Verbose+Input.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.Verbose {
    public struct Input: Decodable, Sendable {
        public let coinbase: String?
        public let scriptSig: ScriptSig?
        public let sequence: UInt
        public let transactionID: String?
        public let indexNumberOfPreviousTransactionOutput: UInt?

        public var isCoinbase: Bool { coinbase != nil }

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Input) throws {
            if let transactionID = payloadModel.txid {
                try SwiftFulcrum.Response.Blockchain.validateTransactionHash(transactionID)
            }
            self.coinbase = payloadModel.coinbase
            self.scriptSig = try payloadModel.scriptSig.map { try ScriptSig(from: $0) }
            self.sequence = payloadModel.sequence
            self.transactionID = payloadModel.txid
            self.indexNumberOfPreviousTransactionOutput = payloadModel.vout
        }
    }
}
