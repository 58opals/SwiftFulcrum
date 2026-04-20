// Response.Result.Server+Ping.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Server {
    public struct Ping: Decodable, Sendable {
        init() {}

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Ping(from: decoder)
            _ = payloadModel
        }
    }
}

extension SwiftFulcrum.RPC.Response.Result.Server.Ping: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { .init() }
}
