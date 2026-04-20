// JSONRPC.Blockchain.Transaction+SubscribeParameters.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction {
    enum SubscribeParameters: Decodable, Sendable {
        case height(UInt)
        case transactionHashAndHeight([TransactionHashAndHeight])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let uintResult = try? container.decode(UInt.self) {
                self = .height(uintResult)
                return
            }

            if let stringAndUIntResult = try? container.decode([TransactionHashAndHeight].self) {
                self = .transactionHashAndHeight(stringAndUIntResult)
                return
            }

            throw DecodingError.typeMismatch(
                SubscribeParameters.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected UInt (height) or String and UInt (transaction hash and height)"
                )
            )
        }
    }
}
