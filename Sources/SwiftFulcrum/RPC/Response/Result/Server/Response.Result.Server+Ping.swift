// Response.Server+Ping.swift

import Foundation

extension SwiftFulcrum.Response.Server {
    public struct Ping: Decodable, Sendable {
        init() {}

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Ping(from: decoder)
            _ = payloadModel
        }
    }
}

extension SwiftFulcrum.Response.Server.Ping: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { .init() }
}
