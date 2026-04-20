// JSONRPC.Result.Server+Version.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Server {
    struct Version: Decodable, Sendable {
        let serverVersion: String
        let protocolVersion: String

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            guard !container.isAtEnd else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected server and protocol version pair"
                )
            }

            self.serverVersion = try container.decode(String.self)
            guard !container.isAtEnd else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Missing negotiated protocol version"
                )
            }

            self.protocolVersion = try container.decode(String.self)
        }
    }
}
