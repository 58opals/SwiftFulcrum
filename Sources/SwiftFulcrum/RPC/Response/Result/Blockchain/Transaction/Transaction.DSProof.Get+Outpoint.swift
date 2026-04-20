// Transaction.DSProof.Get+Outpoint.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.DSProof.Get {
    public struct Outpoint: Decodable, Sendable {
        public let transactionID: String
        public let outputIndex: UInt

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get.Outpoint) {
            self.transactionID = payloadModel.txid
            self.outputIndex = payloadModel.vout
        }
    }
}
