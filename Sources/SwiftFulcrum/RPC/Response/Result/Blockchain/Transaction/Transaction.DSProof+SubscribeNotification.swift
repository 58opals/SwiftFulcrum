// Transaction.DSProof+SubscribeNotification.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.DSProof {
    public struct SubscribeNotification: Decodable, Sendable {
        public let subscriptionIdentifier: String
        public let transactionHash: String
        public let proof: Get?

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe(from: decoder)
            switch payloadModel {
            case .transactionHashAndDSProof(let pairs):
                var hashValue: String?
                var proofValue: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get?
                var hasProof = false

                for pair in pairs {
                    switch pair {
                    case .transactionHash(let hash):
                        guard hashValue == nil else {
                            throw ResponseResultDecodeError.unexpectedFormat("Duplicate txHash in DSProof notification payload")
                        }
                        hashValue = hash
                    case .dsProof(let proof):
                        guard !hasProof else {
                            throw ResponseResultDecodeError.unexpectedFormat("Duplicate dsProof in DSProof notification payload")
                        }
                        proofValue = proof
                        hasProof = true
                    }
                }

                guard let hash = hashValue else {
                    throw ResponseResultDecodeError.missingField("transactionHash")
                }
                guard hasProof else {
                    throw ResponseResultDecodeError.missingField("dsProof")
                }

                self.subscriptionIdentifier = hash
                self.transactionHash = hash
                self.proof = proofValue.map { Get(from: $0) }
            case .dsProof(let proof):
                guard let rawProof = proof else {
                    throw ResponseResultDecodeError.unexpectedFormat(
                        "Nil DSProof in notification without accompanying transaction hash"
                    )
                }
                let hash = rawProof.txid
                self.subscriptionIdentifier = hash
                self.transactionHash = hash
                self.proof = Get(from: rawProof)
            }
        }
    }
}
