// OpalDiagnostics.Field~SwiftFulcrumErrorCode.swift

import Foundation
import OpalDiagnostics

extension OpalDiagnostics.Field {
    static func swiftFulcrumErrorCode(for error: Swift.Error) -> String {
        switch error {
        case let error as SwiftFulcrum.Client.Error:
            return swiftFulcrumErrorCode(for: error)
        case let error as SwiftFulcrum.Client.Error.Transport:
            return swiftFulcrumErrorCode(for: error)
        case let error as SwiftFulcrum.Client.Error.Network:
            return swiftFulcrumErrorCode(for: error)
        case let error as SwiftFulcrum.Client.Error.Coding:
            return swiftFulcrumErrorCode(for: error)
        case let error as SwiftFulcrum.Client.Error.ClientIssue:
            return swiftFulcrumErrorCode(for: error)
        case is SwiftFulcrum.Client.Error.Server:
            return "jsonrpc.server_error"
        case let error as JSONRPCCodec.Error:
            return swiftFulcrumErrorCode(for: error)
        case is EncodingError:
            return "jsonrpc.encode_failed"
        case is JSONRPCResponseDecodeError,
             is DecodingError:
            return "jsonrpc.decode_failed"
        case is ResponseResultDecodeError:
            return "jsonrpc.unexpected_format"
        case is URLError:
            return "network.failure"
        case is CancellationError:
            return "client.cancelled"
        default:
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                return "network.failure"
            }
            return "unknown"
        }
    }

    static func swiftFulcrumErrorCode(for error: SwiftFulcrum.Client.Error) -> String {
        switch error {
        case .transport(let transport):
            return swiftFulcrumErrorCode(for: transport)
        case .rpc:
            return "jsonrpc.server_error"
        case .coding(let coding):
            return swiftFulcrumErrorCode(for: coding)
        case .client(let issue):
            return swiftFulcrumErrorCode(for: issue)
        }
    }

    static func swiftFulcrumErrorCode(for error: SwiftFulcrum.Client.Error.Transport) -> String {
        switch error {
        case .setupFailed:
            return "websocket.setup_failed"
        case .connectionClosed:
            return "websocket.connection_closed"
        case .network(let network):
            return swiftFulcrumErrorCode(for: network)
        case .reconnectFailed:
            return "websocket.reconnect_failed"
        case .heartbeatTimeout:
            return "websocket.heartbeat_timeout"
        }
    }

    static func swiftFulcrumErrorCode(for error: SwiftFulcrum.Client.Error.Network) -> String {
        switch error {
        case .tlsNegotiationFailed:
            return "network.tls_negotiation_failed"
        }
    }

    static func swiftFulcrumErrorCode(for error: SwiftFulcrum.Client.Error.Coding) -> String {
        switch error {
        case .encode:
            return "jsonrpc.encode_failed"
        case .decode:
            return "jsonrpc.decode_failed"
        }
    }

    static func swiftFulcrumErrorCode(for error: SwiftFulcrum.Client.Error.ClientIssue) -> String {
        switch error {
        case .urlNotFound:
            return "network.url_not_found"
        case .invalidURL:
            return "network.invalid_url"
        case .duplicateHandler:
            return "client.invalid_state"
        case .cancelled:
            return "client.cancelled"
        case .timeout:
            return "client.timeout"
        case .emptyResponse:
            return "jsonrpc.empty_response"
        case .protocolMismatch:
            return "jsonrpc.protocol_mismatch"
        case .invalidProtocolNegotiationRange:
            return "client.invalid_state"
        case .unknown(let wrappedError):
            return wrappedError.map(swiftFulcrumErrorCode(for:)) ?? "unknown"
        }
    }

    static func swiftFulcrumErrorCode(for error: JSONRPCCodec.Error) -> String {
        switch error {
        case .rpc:
            return "jsonrpc.server_error"
        case .storage:
            return "jsonrpc.unexpected_format"
        case .decodingFailure(let reason, _, _):
            return swiftFulcrumErrorCode(for: reason)
        }
    }

    static func swiftFulcrumErrorCode(for reason: JSONRPCCodec.Error.DecodingFailureReason) -> String {
        switch reason {
        case .generic:
            return "jsonrpc.decode_failed"
        case .idMissing,
             .methodMissing,
             .parametersMissing,
             .errorMissing,
             .unmatchedMethod,
             .unexpectedFormat:
            return "jsonrpc.unexpected_format"
        }
    }
}
