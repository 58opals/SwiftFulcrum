// Response.Result.Server.Features+Host.swift

import Foundation

extension SwiftFulcrum.Response.Server.Features {
    public struct Host: Decodable, Sendable {
        public let sslPort: Int?
        public let tcpPort: Int?
        public let webSocketPort: Int?
        public let secureWebSocketPort: Int?

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features.Host) throws {
            try SwiftFulcrum.Response.Server.Features.validate(payloadModel.ssl_port, field: "host ssl_port", range: 1 ... 65_535)
            try SwiftFulcrum.Response.Server.Features.validate(payloadModel.tcp_port, field: "host tcp_port", range: 1 ... 65_535)
            try SwiftFulcrum.Response.Server.Features.validate(payloadModel.ws_port, field: "host ws_port", range: 1 ... 65_535)
            try SwiftFulcrum.Response.Server.Features.validate(payloadModel.wss_port, field: "host wss_port", range: 1 ... 65_535)

            self.sslPort = payloadModel.ssl_port
            self.tcpPort = payloadModel.tcp_port
            self.webSocketPort = payloadModel.ws_port
            self.secureWebSocketPort = payloadModel.wss_port
        }
    }
}
