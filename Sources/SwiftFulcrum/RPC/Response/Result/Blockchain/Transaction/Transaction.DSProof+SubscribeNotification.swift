// Transaction.DSProof+SubscribeNotification.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.DSProof {
    public struct SubscribeNotification: Decodable, Sendable {
        public let subscriptionIdentifier: String
        public let transactionHash: String
        public let proof: Get?

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe(from: decoder)
            switch payloadModel {
            case .transactionHashAndDSProof(let pairs):
                if pairs.count == 2,
                   case .transactionHash(let hash) = pairs[0],
                   case .dsProof(let proofValue) = pairs[1] {
                    self.subscriptionIdentifier = hash
                    self.transactionHash = hash
                    self.proof = proofValue.map { Get(from: $0) }
                } else if pairs.count == 1,
                          case .dsProof(let proofValue?) = pairs[0] {
                    self.subscriptionIdentifier = proofValue.txid
                    self.transactionHash = proofValue.txid
                    self.proof = Get(from: proofValue)
                } else {
                    throw ResponseResultDecodeError.unexpectedFormat(
                        "Expected DSProof notification payload to contain [txHash, dsProof]; got \(pairs.count) values"
                    )
                }
            case .dsProof(let proof?):
                self.subscriptionIdentifier = proof.txid
                self.transactionHash = proof.txid
                self.proof = Get(from: proof)
            case .dsProof(let proof):
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Expected [txHash, dsProof] for DSProof notification; got proof only: \(String(describing: proof))"
                )
            }
        }
    }
}
