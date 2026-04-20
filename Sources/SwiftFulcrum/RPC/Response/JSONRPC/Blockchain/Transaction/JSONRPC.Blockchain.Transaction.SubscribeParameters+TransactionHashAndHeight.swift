// JSONRPC.Blockchain.Transaction.SubscribeParameters+TransactionHashAndHeight.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.SubscribeParameters {
    enum TransactionHashAndHeight: Decodable, Sendable {
        case transactionHash(String)
        case height(UInt)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let stringResult = try? container.decode(String.self) {
                self = .transactionHash(stringResult)
                return
            }

            if let uintResult = try? container.decode(UInt.self) {
                self = .height(uintResult)
                return
            }

            throw DecodingError.typeMismatch(
                TransactionHashAndHeight.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected UInt or String")
            )
        }
    }
}
