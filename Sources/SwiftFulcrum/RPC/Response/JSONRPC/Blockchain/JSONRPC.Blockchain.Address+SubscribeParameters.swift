// JSONRPC.Blockchain.Address+SubscribeParameters.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address {
    enum SubscribeParameters: Decodable, Sendable {
        case status(String)
        case addressAndStatus([String?])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let singleValue = try? container.decode(String.self) {
                self = .status(singleValue)
                return
            }

            if let multipleValues = try? container.decode([String?].self) {
                self = .addressAndStatus(multipleValues)
                return
            }

            throw DecodingError.typeMismatch(
                SubscribeParameters.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected String or [String?]")
            )
        }
    }
}
