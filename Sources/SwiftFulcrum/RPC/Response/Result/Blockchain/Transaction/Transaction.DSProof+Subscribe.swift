// Transaction.DSProof+Subscribe.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.DSProof {
    public struct Subscribe: Decodable, Sendable {
        public let proof: Lookup?

        init(proof: Lookup?) {
            self.proof = proof
        }

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe(from: decoder)
            switch payloadModel {
            case .dsProof(let proof):
                self.proof = try proof.map { try Lookup(from: $0) }
            case .transactionHashAndDSProof(let pairs):
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Expected DSProof or nil for DSProof.Subscribe initial response; got [txHash, DSProof]: \(pairs)"
                )
            }
        }
    }
}

extension SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Subscribe: JSONRPCResponseDecodeModel.NilValue {
    static var nilValue: Self { .init(proof: nil) }
}
