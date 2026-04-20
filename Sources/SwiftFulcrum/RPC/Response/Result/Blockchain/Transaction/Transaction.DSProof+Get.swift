// Transaction.DSProof+Get.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.DSProof {
    public struct Get: Decodable, Sendable {
        public let dsProofID: String
        public let transactionID: String
        public let hex: String
        public let outpoint: Outpoint
        public let descendants: [String]

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get) {
            self.dsProofID = payloadModel.dspid
            self.transactionID = payloadModel.txid
            self.hex = payloadModel.hex
            self.outpoint = Outpoint(from: payloadModel.outpoint)
            self.descendants = payloadModel.descendants
        }

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get(from: decoder)
            self.init(from: payloadModel)
        }
    }
}
