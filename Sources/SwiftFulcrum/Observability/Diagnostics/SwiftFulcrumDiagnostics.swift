// SwiftFulcrumDiagnostics.swift

import Foundation
import OpalDiagnostics

enum SwiftFulcrumDiagnostics {
    enum Category {
        static let fulcrum = OpalDiagnostics.Category.fulcrum
        static let jsonRPC = OpalDiagnostics.Category(rawValue: "fulcrum.jsonrpc")
        static let webSocket = OpalDiagnostics.Category(rawValue: "fulcrum.websocket")
        static let reconnect = OpalDiagnostics.Category(rawValue: "fulcrum.reconnect")
    }

    enum Event {
        static let jsonRPCRequestEncoded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.jsonrpc.request.encoded")
        static let jsonRPCRequestEncodeFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.jsonrpc.request.encode_failed")
        static let jsonRPCResponseDecoded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.jsonrpc.response.decoded")
        static let jsonRPCResponseDecodeFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.jsonrpc.response.decode_failed")

        static let clientCallBegin = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.call.begin")
        static let clientCallSent = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.call.sent")
        static let clientCallResponseDecoded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.call.response_decoded")
        static let clientCallTimeout = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.call.timeout")
        static let clientCallCancelled = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.call.cancelled")
        static let clientCallFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.call.failed")
        static let clientSubscribeBegin = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscribe.begin")
        static let clientSubscribeSent = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscribe.sent")
        static let clientSubscribeInitialDecoded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscribe.initial_decoded")
        static let clientSubscribeTimeout = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscribe.timeout")
        static let clientSubscribeCancelled = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscribe.cancelled")
        static let clientSubscribeFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscribe.failed")
        static let clientDiagnosticsUpdated = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.diagnostics.updated")
        static let clientSubscriptionsUpdated = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscriptions.updated")
        static let clientHeartbeatTimeout = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.heartbeat.timeout")
        static let clientReconnectRecoveryBegin = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.reconnect_recovery.begin")
        static let clientReconnectRecoverySucceeded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.reconnect_recovery.succeeded")
        static let clientReconnectRecoveryFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.reconnect_recovery.failed")
        static let clientSubscriptionRestored = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscription.restored")
        static let clientSubscriptionRestoreFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscription.restore_failed")
        static let clientSubscriptionRemoved = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscription.removed")
        static let clientSubscriptionAdded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.client.subscription.added")

        static let webSocketConnectBegin = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.connect.begin")
        static let webSocketConnectSucceeded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.connect.succeeded")
        static let webSocketConnectTimeout = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.connect.timeout")
        static let webSocketConnectFailover = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.connect.failover")
        static let webSocketConnectFailoverExhausted = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.connect.failover_exhausted")
        static let webSocketDisconnect = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.disconnect")
        static let webSocketSendBegin = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.send.begin")
        static let webSocketSendSucceeded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.send.succeeded")
        static let webSocketSendFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.send.failed")
        static let webSocketReceiveMessage = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.receive.message")
        static let webSocketReceiveFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.receive.failed")
        static let webSocketReceiveReconnected = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.receive.reconnected")

        static let reconnectAttempt = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.reconnect.attempt")
        static let reconnectSucceeded = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.reconnect.succeeded")
        static let reconnectFailed = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.reconnect.failed")
        static let reconnectMaxAttempts = OpalDiagnostics.Event(rawValue: "swiftfulcrum.websocket.reconnect.max_attempts")
    }

    static func record(
        _ event: OpalDiagnostics.Event,
        category: OpalDiagnostics.Category,
        level: OpalDiagnostics.Level = .debug,
        traceID: OpalDiagnostics.TraceID? = nil,
        fields: [OpalDiagnostics.Field] = []
    ) {
        OpalDiagnostics.logger(category: category).record(
            event: event,
            level: level,
            traceID: traceID,
            fields: fields
        )
    }

    static func traceID(for requestID: UUID) -> OpalDiagnostics.TraceID {
        OpalDiagnostics.TraceID(rawValue: requestID.uuidString)
    }

    static func publicField(_ name: String, _ value: String) -> OpalDiagnostics.Field {
        OpalDiagnostics.Field(name: name, publicValue: value)
    }

    static func publicField(_ name: String, _ value: Int) -> OpalDiagnostics.Field {
        OpalDiagnostics.Field(name: name, value: value)
    }

    static func publicField(_ name: String, _ value: UInt64) -> OpalDiagnostics.Field {
        OpalDiagnostics.Field(name: name, value: value)
    }

    static func publicField(_ name: String, _ value: Bool) -> OpalDiagnostics.Field {
        OpalDiagnostics.Field(name: name, value: value)
    }

    static func publicField(_ name: String, _ value: UUID) -> OpalDiagnostics.Field {
        OpalDiagnostics.Field(name: name, value: value)
    }

    static func privateField(_ name: String, _ value: String) -> OpalDiagnostics.Field {
        OpalDiagnostics.Field(name: name, value: value, privacy: .private)
    }

    static func methodField(_ methodPath: String) -> OpalDiagnostics.Field {
        publicField("method_path", methodPath)
    }

    static func endpointField(_ url: URL) -> OpalDiagnostics.Field {
        privateField("endpoint_url", url.absoluteString)
    }

    static func networkField(_ network: SwiftFulcrum.Client.Configuration.Network) -> OpalDiagnostics.Field {
        publicField("network", network.resourceName)
    }

    static func errorFields(_ error: Swift.Error) -> [OpalDiagnostics.Field] {
        [
            publicField("error_type", String(reflecting: Swift.type(of: error))),
            privateField("error_message", (error as NSError).localizedDescription)
        ]
    }

    static func payloadFields(payloadType: String, byteCount: Int) -> [OpalDiagnostics.Field] {
        [
            publicField("payload_type", payloadType),
            publicField("byte_count", byteCount)
        ]
    }

    static func payloadFields(for message: URLSessionWebSocketTask.Message) -> [OpalDiagnostics.Field] {
        switch message {
        case .data(let data):
            payloadFields(payloadType: "data", byteCount: data.count)
        case .string(let string):
            payloadFields(payloadType: "string", byteCount: string.utf8.count)
        @unknown default:
            payloadFields(payloadType: "unknown", byteCount: 0)
        }
    }
}
