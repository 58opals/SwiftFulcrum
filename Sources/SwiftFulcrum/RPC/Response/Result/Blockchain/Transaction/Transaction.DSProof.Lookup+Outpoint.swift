// Transaction.DSProof.Lookup+Outpoint.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Lookup {
    public struct Outpoint: Decodable, Sendable {
        public let transactionID: String
        public let outputIndex: UInt

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get.Outpoint) throws {
            try SwiftFulcrum.Response.Blockchain.validateTransactionHash(payloadModel.txid)
            self.transactionID = payloadModel.txid
            self.outputIndex = payloadModel.vout
        }
    }
}
