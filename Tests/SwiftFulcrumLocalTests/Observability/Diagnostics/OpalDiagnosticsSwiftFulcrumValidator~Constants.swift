// OpalDiagnosticsSwiftFulcrumValidator~Constants.swift

import Foundation
import OpalDiagnostics
import Testing
@testable import SwiftFulcrum

extension OpalDiagnosticsSwiftFulcrumValidator {
    @Test("SwiftFulcrum diagnostics constants live on OpalDiagnostics")
    func validateSwiftFulcrumDiagnosticsConstantsLiveOnOpalDiagnostics() {
        #expect(OpalDiagnostics.Category.fulcrum.rawValue == "fulcrum")
        #expect(OpalDiagnostics.Category.swiftFulcrumJSONRPC.rawValue == "fulcrum.jsonrpc")
        #expect(OpalDiagnostics.Category.swiftFulcrumWebSocket.rawValue == "fulcrum.websocket")
        #expect(OpalDiagnostics.Category.swiftFulcrumReconnect.rawValue == "fulcrum.reconnect")
        #expect(OpalDiagnostics.Event.swiftFulcrumClientCallBegin.rawValue == "swiftfulcrum.client.call.begin")
        #expect(OpalDiagnostics.Event.swiftFulcrumClientStateUpdated.rawValue == "swiftfulcrum.client.state.updated")
        #expect(OpalDiagnostics.Event.swiftFulcrumReconnectAttempt.rawValue == "swiftfulcrum.websocket.reconnect.attempt")
        let errorCodeField = OpalDiagnostics.Field.errorCode(.jsonRPCDecodeFailed)
        #expect(errorCodeField.name == "error_code")
        #expect(errorCodeField.value == "jsonrpc.decode_failed")
        #expect(errorCodeField.privacy == .public)
    }

    @Test("Default Opal diagnostics configuration does not retain package diagnostics")
    func verifyDefaultOpalDiagnosticsConfigurationDoesNotRetainPackageDiagnostics() {
        OpalDiagnostics.withConfiguration(.init(bufferPolicy: .enabled(capacity: 100))) {
            OpalDiagnostics.clearRecentRecords()
            let request = FulcrumRequest(
                id: UUID(),
                method: SwiftFulcrum.RPC.Method.server(.ping),
                params: ThrowingParametersModel()
            )

            #expect(request.data == nil)
            #expect(OpalDiagnostics.recentRecords.isEmpty)
        }
    }

    @Test("Diagnostics error code catalog maps known failures")
    func mapDiagnosticsErrorCodeCatalogToKnownFailures() {
        let mappings = [
            (
                OpalDiagnostics.Field.errorCode(for: SwiftFulcrum.Client.Error.client(.cancelled)),
                OpalDiagnostics.ErrorCode.clientCancelled,
                "client.cancelled"
            ),
            (
                OpalDiagnostics.Field.errorCode(for: SwiftFulcrum.Client.Error.client(.timeout(.seconds(1)))),
                OpalDiagnostics.ErrorCode.clientTimeout,
                "client.timeout"
            ),
            (
                OpalDiagnostics.Field.errorCode(for: SwiftFulcrum.Client.Error.coding(.decode(nil))),
                OpalDiagnostics.ErrorCode.jsonRPCDecodeFailed,
                "jsonrpc.decode_failed"
            ),
            (
                OpalDiagnostics.Field.errorCode(for: SwiftFulcrum.Client.Error.rpc(.init(id: nil, code: 1, message: "server message"))),
                OpalDiagnostics.ErrorCode.jsonRPCServerError,
                "jsonrpc.server_error"
            ),
            (
                OpalDiagnostics.Field.errorCode(for: SwiftFulcrum.Client.Error.transport(.connectionClosed(.goingAway, "server reason"))),
                OpalDiagnostics.ErrorCode.webSocketConnectionClosed,
                "websocket.connection_closed"
            ),
            (
                OpalDiagnostics.Field.errorCode(for: SwiftFulcrum.Client.Error.transport(.heartbeatTimeout)),
                OpalDiagnostics.ErrorCode.webSocketHeartbeatTimeout,
                "websocket.heartbeat_timeout"
            ),
            (
                OpalDiagnostics.Field.errorCode(for: JSONRPCCodec.Error.decodingFailure(reason: .unexpectedFormat, data: Data([0x01]), description: "payload detail")),
                OpalDiagnostics.ErrorCode.jsonRPCUnexpectedFormat,
                "jsonrpc.unexpected_format"
            ),
            (
                OpalDiagnostics.Field.errorCode(for: URLError(.cancelled)),
                OpalDiagnostics.ErrorCode.clientCancelled,
                "client.cancelled"
            ),
            (
                OpalDiagnostics.Field.errorCode(for: URLError(.timedOut)),
                OpalDiagnostics.ErrorCode.networkFailure,
                "network.failure"
            )
        ]

        for (actual, expected, rawValue) in mappings {
            #expect(actual == expected)
            #expect(actual.rawValue == rawValue)
        }
    }
}
