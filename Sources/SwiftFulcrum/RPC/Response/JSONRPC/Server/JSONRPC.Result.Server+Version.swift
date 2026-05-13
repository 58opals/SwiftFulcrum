// JSONRPC.Result.Server+Version.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Server {
    struct Version: Decodable, Sendable {
        let serverVersion: String
        let protocolVersion: String

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let values = try container.decode([String].self)
            guard values.count == 2 else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected server and protocol version pair"
                )
            }

            self.serverVersion = values[0]
            self.protocolVersion = values[1]
        }
    }
}
