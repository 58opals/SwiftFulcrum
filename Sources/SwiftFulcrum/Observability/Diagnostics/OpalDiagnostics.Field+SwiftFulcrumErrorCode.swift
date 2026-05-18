// OpalDiagnostics.Field+SwiftFulcrumErrorCode.swift

import Foundation
import OpalDiagnostics

extension OpalDiagnostics.Field {
    static func errorCode(for error: Swift.Error) -> OpalDiagnostics.ErrorCode {
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
            return .jsonRPCServerError
        case let error as JSONRPCCodec.Error:
            return errorCode(for: error)
        case is EncodingError:
            return .jsonRPCEncodeFailed
        case is JSONRPCResponseDecodeError,
             is DecodingError:
            return .jsonRPCDecodeFailed
        case is ResponseResultDecodeError:
            return .jsonRPCUnexpectedFormat
        case let error as URLError where error.code == .cancelled:
            return .clientCancelled
        case is URLError:
            return .networkFailure
        case is CancellationError:
            return .clientCancelled
        default:
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                if nsError.code == NSURLErrorCancelled {
                    return .clientCancelled
                }
                return .networkFailure
            }
            return .unknown
        }
    }

    static func errorCode(for error: SwiftFulcrum.Client.Error) -> OpalDiagnostics.ErrorCode {
        switch error {
        case .transport(let transport):
            return errorCode(for: transport)
        case .rpc:
            return .jsonRPCServerError
        case .coding(let coding):
            return errorCode(for: coding)
        case .client(let issue):
            return errorCode(for: issue)
        }
    }

    static func errorCode(for error: SwiftFulcrum.Client.Error.Transport) -> OpalDiagnostics.ErrorCode {
        switch error {
        case .setupFailed:
            return .webSocketSetupFailed
        case .connectionClosed:
            return .webSocketConnectionClosed
        case .network(let network):
            return errorCode(for: network)
        case .reconnectFailed:
            return .webSocketReconnectFailed
        case .heartbeatTimeout:
            return .webSocketHeartbeatTimeout
        }
    }

    static func errorCode(for error: SwiftFulcrum.Client.Error.Network) -> OpalDiagnostics.ErrorCode {
        switch error {
        case .tlsNegotiationFailed:
            return .networkTLSNegotiationFailed
        }
    }

    static func errorCode(for error: SwiftFulcrum.Client.Error.Coding) -> OpalDiagnostics.ErrorCode {
        switch error {
        case .encode:
            return .jsonRPCEncodeFailed
        case .decode:
            return .jsonRPCDecodeFailed
        }
    }

    static func errorCode(for error: SwiftFulcrum.Client.Error.ClientIssue) -> OpalDiagnostics.ErrorCode {
        switch error {
        case .urlNotFound:
            return .networkURLNotFound
        case .invalidURL:
            return .networkInvalidURL
        case .duplicateHandler:
            return .clientInvalidState
        case .cancelled:
            return .clientCancelled
        case .timeout:
            return .clientTimeout
        case .emptyResponse:
            return .jsonRPCEmptyResponse
        case .protocolMismatch:
            return .jsonRPCProtocolMismatch
        case .invalidProtocolNegotiationRange:
            return .clientInvalidState
        case .unknown(let wrappedError):
            return wrappedError.map(errorCode(for:)) ?? .unknown
        }
    }

    static func errorCode(for error: JSONRPCCodec.Error) -> OpalDiagnostics.ErrorCode {
        switch error {
        case .rpc:
            return .jsonRPCServerError
        case .storage:
            return .jsonRPCUnexpectedFormat
        case .decodingFailure(let reason, _, _):
            return errorCode(for: reason)
        }
    }

    static func errorCode(for reason: JSONRPCCodec.Error.DecodingFailureReason) -> OpalDiagnostics.ErrorCode {
        switch reason {
        case .generic:
            return .jsonRPCDecodeFailed
        case .idMissing,
             .methodMissing,
             .parametersMissing,
             .errorMissing,
             .unmatchedMethod,
             .unexpectedFormat:
            return .jsonRPCUnexpectedFormat
        }
    }
}
