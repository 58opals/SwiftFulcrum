// JSONRPC.Result.Server.Features+Host.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features {
    struct Host: Decodable, Sendable {
        let ssl_port: Int?
        let tcp_port: Int?
        let ws_port: Int?
        let wss_port: Int?
    }
}
