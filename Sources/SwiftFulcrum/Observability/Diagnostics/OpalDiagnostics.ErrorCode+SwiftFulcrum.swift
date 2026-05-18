// OpalDiagnostics.ErrorCode+SwiftFulcrum.swift

import OpalDiagnostics

extension OpalDiagnostics.ErrorCode {
    static let clientCancelled = Self(rawValue: "client.cancelled")
    static let clientInvalidState = Self(rawValue: "client.invalid_state")
    static let clientTimeout = Self(rawValue: "client.timeout")
    static let jsonRPCDecodeFailed = Self(rawValue: "jsonrpc.decode_failed")
    static let jsonRPCEmptyResponse = Self(rawValue: "jsonrpc.empty_response")
    static let jsonRPCEncodeFailed = Self(rawValue: "jsonrpc.encode_failed")
    static let jsonRPCProtocolMismatch = Self(rawValue: "jsonrpc.protocol_mismatch")
    static let jsonRPCServerError = Self(rawValue: "jsonrpc.server_error")
    static let jsonRPCUnexpectedFormat = Self(rawValue: "jsonrpc.unexpected_format")
    static let networkFailure = Self(rawValue: "network.failure")
    static let networkInvalidURL = Self(rawValue: "network.invalid_url")
    static let networkTLSNegotiationFailed = Self(rawValue: "network.tls_negotiation_failed")
    static let networkURLNotFound = Self(rawValue: "network.url_not_found")
    static let unknown = Self(rawValue: "unknown")
    static let webSocketConnectionClosed = Self(rawValue: "websocket.connection_closed")
    static let webSocketHeartbeatTimeout = Self(rawValue: "websocket.heartbeat_timeout")
    static let webSocketReconnectFailed = Self(rawValue: "websocket.reconnect_failed")
    static let webSocketSetupFailed = Self(rawValue: "websocket.setup_failed")
}
