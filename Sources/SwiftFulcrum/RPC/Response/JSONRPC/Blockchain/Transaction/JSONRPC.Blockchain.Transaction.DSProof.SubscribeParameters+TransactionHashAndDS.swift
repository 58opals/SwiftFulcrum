// JSONRPC.Blockchain.Transaction.DSProof.SubscribeParameters+TransactionHashAndDS.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.SubscribeParameters {
    enum TransactionHashAndDS: Decodable, Sendable {
        case transactionHash(String)
        case dsProof(SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let stringResult = try? container.decode(String.self) {
                self = .transactionHash(stringResult)
                return
            }

            if let getResult = try? container.decode(SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get.self) {
                self = .dsProof(getResult)
                return
            }

            throw DecodingError.typeMismatch(
                TransactionHashAndDS.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected transaction hash or double-spending proof")
            )
        }
    }
}
