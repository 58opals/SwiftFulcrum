// SwiftFulcrumDiagnostics.swift

import Foundation
import OpalDiagnostics

enum SwiftFulcrumDiagnostics {
    typealias Diagnostics = SwiftFulcrum.Client.Diagnostics

    enum Category {
        static let fulcrum = Diagnostics.Category.fulcrum
        static let jsonRPC = Diagnostics.Category.jsonRPC
        static let webSocket = Diagnostics.Category.webSocket
        static let reconnect = Diagnostics.Category.reconnect
    }

    enum Event {
        static let jsonRPCRequestEncoded = Diagnostics.Event.jsonRPCRequestEncoded
        static let jsonRPCRequestEncodeFailed = Diagnostics.Event.jsonRPCRequestEncodeFailed
        static let jsonRPCResponseDecoded = Diagnostics.Event.jsonRPCResponseDecoded
        static let jsonRPCResponseDecodeFailed = Diagnostics.Event.jsonRPCResponseDecodeFailed

        static let clientCallBegin = Diagnostics.Event.clientCallBegin
        static let clientCallSent = Diagnostics.Event.clientCallSent
        static let clientCallResponseDecoded = Diagnostics.Event.clientCallResponseDecoded
        static let clientCallTimeout = Diagnostics.Event.clientCallTimeout
        static let clientCallCancelled = Diagnostics.Event.clientCallCancelled
        static let clientCallFailed = Diagnostics.Event.clientCallFailed
        static let clientSubscribeBegin = Diagnostics.Event.clientSubscribeBegin
        static let clientSubscribeSent = Diagnostics.Event.clientSubscribeSent
        static let clientSubscribeInitialDecoded = Diagnostics.Event.clientSubscribeInitialDecoded
        static let clientSubscribeTimeout = Diagnostics.Event.clientSubscribeTimeout
        static let clientSubscribeCancelled = Diagnostics.Event.clientSubscribeCancelled
        static let clientSubscribeFailed = Diagnostics.Event.clientSubscribeFailed
        static let clientDiagnosticsUpdated = Diagnostics.Event.clientDiagnosticsUpdated
        static let clientSubscriptionsUpdated = Diagnostics.Event.clientSubscriptionsUpdated
        static let clientHeartbeatTimeout = Diagnostics.Event.clientHeartbeatTimeout
        static let clientReconnectRecoveryBegin = Diagnostics.Event.clientReconnectRecoveryBegin
        static let clientReconnectRecoverySucceeded = Diagnostics.Event.clientReconnectRecoverySucceeded
        static let clientReconnectRecoveryFailed = Diagnostics.Event.clientReconnectRecoveryFailed
        static let clientSubscriptionRestored = Diagnostics.Event.clientSubscriptionRestored
        static let clientSubscriptionRestoreFailed = Diagnostics.Event.clientSubscriptionRestoreFailed
        static let clientSubscriptionRemoved = Diagnostics.Event.clientSubscriptionRemoved
        static let clientSubscriptionAdded = Diagnostics.Event.clientSubscriptionAdded

        static let webSocketConnectBegin = Diagnostics.Event.webSocketConnectBegin
        static let webSocketConnectSucceeded = Diagnostics.Event.webSocketConnectSucceeded
        static let webSocketConnectTimeout = Diagnostics.Event.webSocketConnectTimeout
        static let webSocketConnectFailover = Diagnostics.Event.webSocketConnectFailover
        static let webSocketConnectFailoverExhausted = Diagnostics.Event.webSocketConnectFailoverExhausted
        static let webSocketDisconnect = Diagnostics.Event.webSocketDisconnect
        static let webSocketSendBegin = Diagnostics.Event.webSocketSendBegin
        static let webSocketSendSucceeded = Diagnostics.Event.webSocketSendSucceeded
        static let webSocketSendFailed = Diagnostics.Event.webSocketSendFailed
        static let webSocketReceiveMessage = Diagnostics.Event.webSocketReceiveMessage
        static let webSocketReceiveFailed = Diagnostics.Event.webSocketReceiveFailed
        static let webSocketReceiveReconnected = Diagnostics.Event.webSocketReceiveReconnected

        static let reconnectAttempt = Diagnostics.Event.reconnectAttempt
        static let reconnectSucceeded = Diagnostics.Event.reconnectSucceeded
        static let reconnectFailed = Diagnostics.Event.reconnectFailed
        static let reconnectMaxAttempts = Diagnostics.Event.reconnectMaxAttempts
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
            errorCodeField(errorCode(for: error)),
            publicField("error_type", String(reflecting: Swift.type(of: error))),
            privateField("error_message", (error as NSError).localizedDescription)
        ]
    }

    static func errorCodeField(_ errorCode: String) -> OpalDiagnostics.Field {
        publicField(Diagnostics.Field.errorCode, errorCode)
    }

    static func errorCode(for error: Swift.Error) -> String {
        switch error {
        case let error as SwiftFulcrum.Client.Error:
            return errorCode(for: error)
        case let error as SwiftFulcrum.Client.Error.Transport:
            return errorCode(for: error)
        case let error as SwiftFulcrum.Client.Error.Network:
            return errorCode(for: error)
        case let error as SwiftFulcrum.Client.Error.Coding:
            return errorCode(for: error)
        case let error as SwiftFulcrum.Client.Error.ClientIssue:
            return errorCode(for: error)
        case is SwiftFulcrum.Client.Error.Server:
            return Diagnostics.ErrorCode.jsonRPCServerError
        case let error as JSONRPCCodec.Error:
            return errorCode(for: error)
        case is EncodingError:
            return Diagnostics.ErrorCode.jsonRPCEncodeFailed
        case is JSONRPCResponseDecodeError,
             is DecodingError:
            return Diagnostics.ErrorCode.jsonRPCDecodeFailed
        case is ResponseResultDecodeError:
            return Diagnostics.ErrorCode.jsonRPCUnexpectedFormat
        case is URLError:
            return Diagnostics.ErrorCode.networkFailure
        case is CancellationError:
            return Diagnostics.ErrorCode.clientCancelled
        default:
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                return Diagnostics.ErrorCode.networkFailure
            }
            return Diagnostics.ErrorCode.unknown
        }
    }

    static func errorCode(for error: SwiftFulcrum.Client.Error) -> String {
        switch error {
        case .transport(let transport):
            return errorCode(for: transport)
        case .rpc:
            return Diagnostics.ErrorCode.jsonRPCServerError
        case .coding(let coding):
            return errorCode(for: coding)
        case .client(let issue):
            return errorCode(for: issue)
        }
    }

    static func errorCode(for error: SwiftFulcrum.Client.Error.Transport) -> String {
        switch error {
        case .setupFailed:
            return Diagnostics.ErrorCode.webSocketSetupFailed
        case .connectionClosed:
            return Diagnostics.ErrorCode.webSocketConnectionClosed
        case .network(let network):
            return errorCode(for: network)
        case .reconnectFailed:
            return Diagnostics.ErrorCode.webSocketReconnectFailed
        case .heartbeatTimeout:
            return Diagnostics.ErrorCode.webSocketHeartbeatTimeout
        }
    }

    static func errorCode(for error: SwiftFulcrum.Client.Error.Network) -> String {
        switch error {
        case .tlsNegotiationFailed:
            return Diagnostics.ErrorCode.networkTLSNegotiationFailed
        }
    }

    static func errorCode(for error: SwiftFulcrum.Client.Error.Coding) -> String {
        switch error {
        case .encode:
            return Diagnostics.ErrorCode.jsonRPCEncodeFailed
        case .decode:
            return Diagnostics.ErrorCode.jsonRPCDecodeFailed
        }
    }

    static func errorCode(for error: SwiftFulcrum.Client.Error.ClientIssue) -> String {
        switch error {
        case .urlNotFound:
            return Diagnostics.ErrorCode.networkURLNotFound
        case .invalidURL:
            return Diagnostics.ErrorCode.networkInvalidURL
        case .duplicateHandler:
            return Diagnostics.ErrorCode.clientInvalidState
        case .cancelled:
            return Diagnostics.ErrorCode.clientCancelled
        case .timeout:
            return Diagnostics.ErrorCode.clientTimeout
        case .emptyResponse:
            return Diagnostics.ErrorCode.jsonRPCEmptyResponse
        case .protocolMismatch:
            return Diagnostics.ErrorCode.jsonRPCProtocolMismatch
        case .invalidProtocolNegotiationRange:
            return Diagnostics.ErrorCode.clientInvalidState
        case .unknown(let wrappedError):
            return wrappedError.map(errorCode(for:)) ?? Diagnostics.ErrorCode.unknown
        }
    }

    static func errorCode(for error: JSONRPCCodec.Error) -> String {
        switch error {
        case .rpc:
            return Diagnostics.ErrorCode.jsonRPCServerError
        case .storage:
            return Diagnostics.ErrorCode.jsonRPCUnexpectedFormat
        case .decodingFailure(let reason, _, _):
            return errorCode(for: reason)
        }
    }

    static func errorCode(for reason: JSONRPCCodec.Error.DecodingFailureReason) -> String {
        switch reason {
        case .generic:
            return Diagnostics.ErrorCode.jsonRPCDecodeFailed
        case .idMissing,
             .methodMissing,
             .parametersMissing,
             .errorMissing,
             .unmatchedMethod,
             .unexpectedFormat:
            return Diagnostics.ErrorCode.jsonRPCUnexpectedFormat
        }
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
