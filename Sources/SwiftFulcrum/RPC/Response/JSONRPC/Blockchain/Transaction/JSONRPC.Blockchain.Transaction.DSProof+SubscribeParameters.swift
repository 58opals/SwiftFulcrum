// JSONRPC.Blockchain.Transaction.DSProof+SubscribeParameters.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof {
    enum SubscribeParameters: Decodable, Sendable {
        case dsProof(Get?)
        case transactionHashAndDSProof([TransactionHashAndDS])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if container.decodeNil() {
                self = .dsProof(nil)
                return
            }

            if let getResult = try? container.decode(Get?.self) {
                self = .dsProof(getResult)
                return
            }

            if let stringAndGetResult = try? container.decode([TransactionHashAndDS].self) {
                self = .transactionHashAndDSProof(stringAndGetResult)
                return
            }

            throw DecodingError.typeMismatch(
                SubscribeParameters.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected nil, a DSProof, or [txHash, dsProof]")
            )
        }
    }
}
