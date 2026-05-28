// Transaction.DSProof+SubscribeNotification.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.DSProof {
    public struct SubscribeNotification: Decodable, Sendable {
        public let subscriptionIdentifier: String
        public let transactionHash: String
        public let proof: Lookup?

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe(from: decoder)
            switch payloadModel {
            case .transactionHashAndDSProof(let pairs):
                if pairs.count == 2,
                   case .transactionHash(let hash) = pairs[0],
                   case .dsProof(let proofValue) = pairs[1] {
                    try SwiftFulcrum.Response.Blockchain.validateTransactionHash(hash)
                    let proof = try proofValue.map { try Lookup(from: $0) }
                    if let proofTransactionHash = proof?.transactionID, proofTransactionHash != hash {
                        throw ResponseResultDecodeError.unexpectedFormat(
                            "Expected DSProof notification hash to match proof transaction hash"
                        )
                    }
                    self.init(transactionHash: hash, proof: proof)
                } else if pairs.count == 1,
                          case .dsProof(let proofValue?) = pairs[0] {
                    try self.init(proofValue: proofValue)
                } else {
                    throw ResponseResultDecodeError.unexpectedFormat(
                        "Expected DSProof notification payload to contain [txHash, dsProof]; got \(pairs.count) values"
                    )
                }
            case .dsProof(let proof?):
                try self.init(proofValue: proof)
            case .dsProof(let proof):
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Expected [txHash, dsProof] for DSProof notification; got proof only: \(String(describing: proof))"
                )
            }
        }

        private init(
            proofValue: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get
        ) throws {
            self.init(transactionHash: proofValue.txid, proof: try Lookup(from: proofValue))
        }

        private init(transactionHash: String, proof: Lookup?) {
            self.subscriptionIdentifier = transactionHash
            self.transactionHash = transactionHash
            self.proof = proof
        }
    }
}
