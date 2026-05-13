// Transaction.DSProof+Get.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.DSProof {
    public struct Get: Decodable, Sendable {
        public let dsProofID: String?
        public let transactionID: String?
        public let hex: String?
        public let outpoint: Outpoint?
        public let descendants: [String]
        public var isFound: Bool { dsProofID != nil }

        init(
            dsProofID: String?,
            transactionID: String?,
            hex: String?,
            outpoint: Outpoint?,
            descendants: [String]
        ) {
            self.dsProofID = dsProofID
            self.transactionID = transactionID
            self.hex = hex
            self.outpoint = outpoint
            self.descendants = descendants
        }

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

extension SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Get: JSONRPCResponseDecodeModel.NilValue {
    static var nilValue: Self {
        .init(dsProofID: nil, transactionID: nil, hex: nil, outpoint: nil, descendants: .init())
    }
}
