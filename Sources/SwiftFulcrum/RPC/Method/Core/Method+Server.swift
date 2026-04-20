// Method+Server.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    public enum Server: Sendable {
        case ping
        case version(
            clientName: String,
            protocolNegotiation: SwiftFulcrum.Client.Configuration.ProtocolNegotiation.Argument
        )
        case features
    }
}
