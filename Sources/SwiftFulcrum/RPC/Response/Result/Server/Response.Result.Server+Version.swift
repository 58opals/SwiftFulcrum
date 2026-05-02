// Response.Server+Version.swift

import Foundation

extension SwiftFulcrum.Response.Server {
    public struct Version: Decodable, Sendable {
        public let serverVersion: String
        public let negotiatedProtocolVersion: SwiftFulcrum.ProtocolVersion

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Version(from: decoder)

            guard let protocolVersion = SwiftFulcrum.ProtocolVersion(string: payloadModel.protocolVersion) else {
                throw ResponseResultDecodeError.unexpectedFormat("Negotiated protocol version is invalid: \(payloadModel.protocolVersion)")
            }

            self.serverVersion = payloadModel.serverVersion
            self.negotiatedProtocolVersion = protocolVersion
        }
    }
}
