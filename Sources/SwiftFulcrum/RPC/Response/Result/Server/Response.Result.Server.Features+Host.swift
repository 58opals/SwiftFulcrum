// Response.Result.Server.Features+Host.swift

import Foundation

extension SwiftFulcrum.Response.Server.Features {
    public struct Host: Decodable, Sendable {
        public let sslPort: Int?
        public let tcpPort: Int?
        public let webSocketPort: Int?
        public let secureWebSocketPort: Int?

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features.Host) throws {
            try SwiftFulcrum.Response.Server.Features.validatePort(payloadModel.ssl_port, field: "host ssl_port")
            try SwiftFulcrum.Response.Server.Features.validatePort(payloadModel.tcp_port, field: "host tcp_port")
            try SwiftFulcrum.Response.Server.Features.validatePort(payloadModel.ws_port, field: "host ws_port")
            try SwiftFulcrum.Response.Server.Features.validatePort(payloadModel.wss_port, field: "host wss_port")

            self.sslPort = payloadModel.ssl_port
            self.tcpPort = payloadModel.tcp_port
            self.webSocketPort = payloadModel.ws_port
            self.secureWebSocketPort = payloadModel.wss_port
        }
    }
}
