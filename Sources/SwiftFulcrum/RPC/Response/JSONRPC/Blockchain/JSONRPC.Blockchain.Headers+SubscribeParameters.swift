// JSONRPC.Blockchain.Headers+SubscribeParameters.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Headers {
    enum SubscribeParameters: Decodable, Sendable {
        case topHeader(Tip)
        case newHeader([Tip])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let singleValue = try? container.decode(Tip.self) {
                self = .topHeader(singleValue)
                return
            }

            if let multipleValues = try? container.decode([Tip].self) {
                self = .newHeader(multipleValues)
                return
            }

            throw DecodingError.typeMismatch(
                SubscribeParameters.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected top header's height and hex or new headers' heights and hexes"
                )
            )
        }
    }
}
