// Response.Result.Server.Features+Host.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Server.Features {
    public struct Host: Decodable, Sendable {
        public let sslPort: Int?
        public let tcpPort: Int?
        public let webSocketPort: Int?
        public let secureWebSocketPort: Int?

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features.Host) {
            self.sslPort = payloadModel.ssl_port
            self.tcpPort = payloadModel.tcp_port
            self.webSocketPort = payloadModel.ws_port
            self.secureWebSocketPort = payloadModel.wss_port
        }
    }
}
