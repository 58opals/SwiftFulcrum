// Client.Diagnostics+Catalog.swift

public import OpalDiagnostics

extension SwiftFulcrum.Client.Diagnostics {
    /// Stable diagnostics categories that callers may use with OpalDiagnostics filters.
    public enum Category {
        public static let fulcrum: OpalDiagnostics.Category = OpalDiagnostics.Category.fulcrum
        public static let jsonRPC = OpalDiagnostics.Category(rawValue: "fulcrum.jsonrpc")
        public static let webSocket = OpalDiagnostics.Category(rawValue: "fulcrum.websocket")
        public static let reconnect = OpalDiagnostics.Category(rawValue: "fulcrum.reconnect")
    }

    /// Stable diagnostics events that callers may use with OpalDiagnostics filters.
    public enum Event {
        public static let jsonRPCRequestEncoded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.jsonrpc.request.encoded")
        public static let jsonRPCRequestEncodeFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.jsonrpc.request.encode_failed")
        public static let jsonRPCResponseDecoded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.jsonrpc.response.decoded")
        public static let jsonRPCResponseDecodeFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.jsonrpc.response.decode_failed")

        public static let clientCallBegin = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.call.begin")
        public static let clientCallSent = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.call.sent")
        public static let clientCallResponseDecoded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.call.response_decoded")
        public static let clientCallTimeout = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.call.timeout")
        public static let clientCallCancelled = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.call.cancelled")
        public static let clientCallFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.call.failed")
        public static let clientSubscribeBegin = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscribe.begin")
        public static let clientSubscribeSent = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscribe.sent")
        public static let clientSubscribeInitialDecoded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscribe.initial_decoded")
        public static let clientSubscribeTimeout = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscribe.timeout")
        public static let clientSubscribeCancelled = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscribe.cancelled")
        public static let clientSubscribeFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscribe.failed")
        public static let clientDiagnosticsUpdated = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.diagnostics.updated")
        public static let clientSubscriptionsUpdated = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscriptions.updated")
        public static let clientHeartbeatTimeout = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.heartbeat.timeout")
        public static let clientReconnectRecoveryBegin = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.reconnect_recovery.begin")
        public static let clientReconnectRecoverySucceeded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.reconnect_recovery.succeeded")
        public static let clientReconnectRecoveryFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.reconnect_recovery.failed")
        public static let clientSubscriptionRestored = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscription.restored")
        public static let clientSubscriptionRestoreFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscription.restore_failed")
        public static let clientSubscriptionRemoved = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscription.removed")
        public static let clientSubscriptionAdded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscription.added")

        public static let webSocketConnectBegin = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.connect.begin")
        public static let webSocketConnectSucceeded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.connect.succeeded")
        public static let webSocketConnectTimeout = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.connect.timeout")
        public static let webSocketConnectFailover = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.connect.failover")
        public static let webSocketConnectFailoverExhausted = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.connect.failover_exhausted")
        public static let webSocketDisconnect = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.disconnect")
        public static let webSocketSendBegin = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.send.begin")
        public static let webSocketSendSucceeded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.send.succeeded")
        public static let webSocketSendFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.send.failed")
        public static let webSocketReceiveMessage = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.receive.message")
        public static let webSocketReceiveFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.receive.failed")
        public static let webSocketReceiveReconnected = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.receive.reconnected")

        public static let reconnectAttempt = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.reconnect.attempt")
        public static let reconnectSucceeded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.reconnect.succeeded")
        public static let reconnectFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.reconnect.failed")
        public static let reconnectMaxAttempts = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.reconnect.max_attempts")
    }

    /// Stable public diagnostics field names.
    public enum Field {
        public static let errorCode = "error_code"
    }

    /// Stable public diagnostics error codes for common failure classes.
    public enum ErrorCode {
        public static let unknown = "unknown"
        public static let clientCancelled = "client.cancelled"
        public static let clientTimeout = "client.timeout"
        public static let clientInvalidState = "client.invalid_state"
        public static let jsonRPCEncodeFailed = "jsonrpc.encode_failed"
        public static let jsonRPCDecodeFailed = "jsonrpc.decode_failed"
        public static let jsonRPCEmptyResponse = "jsonrpc.empty_response"
        public static let jsonRPCProtocolMismatch = "jsonrpc.protocol_mismatch"
        public static let jsonRPCServerError = "jsonrpc.server_error"
        public static let jsonRPCUnexpectedFormat = "jsonrpc.unexpected_format"
        public static let networkFailure = "network.failure"
        public static let networkInvalidURL = "network.invalid_url"
        public static let networkURLNotFound = "network.url_not_found"
        public static let networkTLSNegotiationFailed = "network.tls_negotiation_failed"
        public static let webSocketSetupFailed = "websocket.setup_failed"
        public static let webSocketConnectionClosed = "websocket.connection_closed"
        public static let webSocketReconnectFailed = "websocket.reconnect_failed"
        public static let webSocketHeartbeatTimeout = "websocket.heartbeat_timeout"
    }
}
