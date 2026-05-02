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
                guard pairs.count == 2 else {
                    throw ResponseResultDecodeError.unexpectedFormat(
                        "Expected DSProof notification payload to contain [txHash, dsProof]; got \(pairs.count) values"
                    )
                }
                guard case .transactionHash(let hash) = pairs[0] else {
                    throw ResponseResultDecodeError.unexpectedFormat("Expected transaction hash as first DSProof notification value")
                }
                guard case .dsProof(let proofValue) = pairs[1] else {
                    throw ResponseResultDecodeError.unexpectedFormat("Expected DSProof as second notification value")
                }

                self.subscriptionIdentifier = hash
                self.transactionHash = hash
                self.proof = proofValue.map { Get(from: $0) }
            case .dsProof(let proof):
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Expected [txHash, dsProof] for DSProof notification; got proof only: \(String(describing: proof))"
                )
            }
        }
    }
}
