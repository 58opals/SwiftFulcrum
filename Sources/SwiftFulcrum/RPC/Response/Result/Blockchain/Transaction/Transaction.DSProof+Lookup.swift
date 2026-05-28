// Transaction.DSProof+Lookup.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.DSProof {
    public struct Lookup: Decodable, Sendable {
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

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get) throws {
            try SwiftFulcrum.Response.Blockchain.validateDoubleSpendProofIdentifier(payloadModel.dspid)
            try SwiftFulcrum.Response.Blockchain.validateTransactionHash(payloadModel.txid)
            try SwiftFulcrum.Response.Blockchain.validateNonEmptyHexString(payloadModel.hex, description: "DSProof hex")
            try SwiftFulcrum.Response.Blockchain.validateTransactionHashes(
                payloadModel.descendants,
                description: "DSProof descendant transaction hash"
            )
            self.dsProofID = payloadModel.dspid
            self.transactionID = payloadModel.txid
            self.hex = payloadModel.hex
            self.outpoint = try Outpoint(from: payloadModel.outpoint)
            self.descendants = payloadModel.descendants
        }

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get(from: decoder)
            try self.init(from: payloadModel)
        }
    }
}

extension SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Lookup: JSONRPCResponseDecodeModel.NilValue {
    static var nilValue: Self {
        .init(dsProofID: nil, transactionID: nil, hex: nil, outpoint: nil, descendants: .init())
    }
}
