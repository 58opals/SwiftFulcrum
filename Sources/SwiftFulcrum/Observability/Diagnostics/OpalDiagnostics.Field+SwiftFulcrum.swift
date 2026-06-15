// OpalDiagnostics.Field+SwiftFulcrum.swift

import Foundation
import OpalDiagnostics

extension OpalDiagnostics.Field {
    static func swiftFulcrumField(_ name: String, _ value: String) -> Self {
        .publicField(name, value: value)
    }

    static func swiftFulcrumField(_ name: String, _ value: Int) -> Self {
        Self(name: name, value: value)
    }

    static func swiftFulcrumField(_ name: String, _ value: UInt64) -> Self {
        Self(name: name, value: value)
    }

    static func swiftFulcrumField(_ name: String, _ value: Bool) -> Self {
        Self(name: name, value: value)
    }

    static func swiftFulcrumField(_ name: String, _ value: UUID) -> Self {
        Self(name: name, value: value)
    }

    static func swiftFulcrumPrivateField(_ name: String, _ value: String) -> Self {
        .privateField(name, value: value)
    }

    static func swiftFulcrumMethodPath(_ methodPath: String) -> Self {
        swiftFulcrumField("method_path", methodPath)
    }

    static func swiftFulcrumEndpointURL(_ url: URL) -> Self {
        swiftFulcrumPrivateField("endpoint_url", url.absoluteString)
    }

    static func swiftFulcrumNetwork(_ network: SwiftFulcrum.Client.Configuration.Network) -> Self {
        swiftFulcrumField("network", network.resourceName)
    }

    static func swiftFulcrumErrorFields(_ error: Swift.Error) -> [Self] {
        [
            OpalDiagnostics.Field.errorCode(errorCode(for: error)),
            OpalDiagnostics.Field.errorType(error),
            OpalDiagnostics.Field.errorMessage(swiftFulcrumErrorSummary(error))
        ]
    }

    static func swiftFulcrumPayloadFields(payloadType: String, byteCount: Int) -> [Self] {
        [
            swiftFulcrumField("payload_type", payloadType),
            swiftFulcrumField("byte_count", byteCount)
        ]
    }

    static func swiftFulcrumPayloadFields(for message: URLSessionWebSocketTask.Message) -> [Self] {
        switch message {
        case .data(let data):
            swiftFulcrumPayloadFields(payloadType: "data", byteCount: data.count)
        case .string(let string):
            swiftFulcrumPayloadFields(payloadType: "string", byteCount: string.utf8.count)
        @unknown default:
            swiftFulcrumPayloadFields(payloadType: "unknown", byteCount: 0)
        }
    }
}

private extension OpalDiagnostics.Field {
    static func swiftFulcrumErrorSummary(_ error: Swift.Error) -> String {
        switch error {
        case let error as ResponseResultDecodeError:
            responseResultDecodeErrorSummary(error)
        case let error as JSONRPCCodec.Error:
            jsonRPCCodecErrorSummary(error)
        case let error as SwiftFulcrum.Client.Error:
            clientErrorSummary(error)
        case let error as URLError:
            "URL error code \(error.code.rawValue)"
        case is CancellationError:
            "Operation cancelled"
        default:
            String(reflecting: type(of: error))
        }
    }

    static func responseResultDecodeErrorSummary(_ error: ResponseResultDecodeError) -> String {
        switch error {
        case .missingField(let field):
            "Missing response field: \(field)"
        case .unexpectedFormat:
            "Response payload had unexpected format"
        }
    }

    static func jsonRPCCodecErrorSummary(_ error: JSONRPCCodec.Error) -> String {
        switch error {
        case .rpc(_, let methodPath, _):
            "JSON-RPC server error for method \(methodPath)"
        case .storage:
            "JSON-RPC storage error"
        case .decodingFailure(let reason, let data, _):
            if let data {
                "JSON-RPC decoding failed: \(reason.summary), payload bytes \(data.count)"
            } else {
                "JSON-RPC decoding failed: \(reason.summary)"
            }
        }
    }

    static func clientErrorSummary(_ error: SwiftFulcrum.Client.Error) -> String {
        switch error {
        case .transport(let transportError):
            transportError.summary
        case .rpc(let serverError):
            "RPC server error code \(serverError.code)"
        case .coding(let codingError):
            codingError.summary
        case .client(let clientIssue):
            clientIssue.summary
        }
    }
}

private extension JSONRPCCodec.Error.DecodingFailureReason {
    var summary: String {
        switch self {
        case .generic:
            "generic"
        case .idMissing:
            "id missing"
        case .methodMissing:
            "method missing"
        case .parametersMissing:
            "parameters missing"
        case .errorMissing:
            "error missing"
        case .unmatchedMethod:
            "unmatched method"
        case .unexpectedFormat:
            "unexpected format"
        }
    }
}

private extension SwiftFulcrum.Client.Error.Transport {
    var summary: String {
        switch self {
        case .setupFailed:
            "Transport setup failed"
        case .connectionClosed(let closeCode, _):
            "WebSocket connection closed with code \(closeCode.rawValue)"
        case .network:
            "Transport network failure"
        case .reconnectFailed:
            "WebSocket reconnect failed"
        case .heartbeatTimeout:
            "WebSocket heartbeat timed out"
        }
    }
}

private extension SwiftFulcrum.Client.Error.Coding {
    var summary: String {
        switch self {
        case .encode:
            "Request encoding failed"
        case .decode:
            "Response decoding failed"
        }
    }
}

private extension SwiftFulcrum.Client.Error.ClientIssue {
    var summary: String {
        switch self {
        case .urlNotFound:
            "Endpoint URL not found"
        case .invalidURL:
            "Endpoint URL is invalid"
        case .duplicateHandler:
            "Duplicate response handler"
        case .cancelled:
            "Operation cancelled"
        case .timeout(let duration):
            "Operation timed out after \(duration)"
        case .emptyResponse:
            "JSON-RPC response was empty"
        case .protocolMismatch:
            "Protocol state mismatch"
        case .invalidProtocolNegotiationRange(let minimumVersion, let maximumVersion):
            "Invalid protocol negotiation range \(minimumVersion)...\(maximumVersion)"
        case .unknown:
            "Unknown client error"
        }
    }
}
