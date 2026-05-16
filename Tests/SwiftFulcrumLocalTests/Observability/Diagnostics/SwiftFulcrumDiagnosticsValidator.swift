// SwiftFulcrumDiagnosticsValidator.swift

import Foundation
import OpalDiagnostics
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.serialized, .tags(.local))
struct SwiftFulcrumDiagnosticsValidator {
    @Test("Public diagnostics catalog maps to recorded Opal diagnostics values")
    func publicDiagnosticsCatalogMatchesRecordedCatalog() {
        let categoryMappings = [
            (SwiftFulcrum.Client.Diagnostics.Category.fulcrum, SwiftFulcrumDiagnostics.Category.fulcrum),
            (SwiftFulcrum.Client.Diagnostics.Category.jsonRPC, SwiftFulcrumDiagnostics.Category.jsonRPC),
            (SwiftFulcrum.Client.Diagnostics.Category.webSocket, SwiftFulcrumDiagnostics.Category.webSocket),
            (SwiftFulcrum.Client.Diagnostics.Category.reconnect, SwiftFulcrumDiagnostics.Category.reconnect)
        ]

        for (publicCategory, internalCategory) in categoryMappings {
            #expect(publicCategory == internalCategory)
        }

        let eventMappings = [
            (SwiftFulcrum.Client.Diagnostics.Event.jsonRPCRequestEncoded, SwiftFulcrumDiagnostics.Event.jsonRPCRequestEncoded),
            (SwiftFulcrum.Client.Diagnostics.Event.jsonRPCRequestEncodeFailed, SwiftFulcrumDiagnostics.Event.jsonRPCRequestEncodeFailed),
            (SwiftFulcrum.Client.Diagnostics.Event.jsonRPCResponseDecoded, SwiftFulcrumDiagnostics.Event.jsonRPCResponseDecoded),
            (SwiftFulcrum.Client.Diagnostics.Event.jsonRPCResponseDecodeFailed, SwiftFulcrumDiagnostics.Event.jsonRPCResponseDecodeFailed),
            (SwiftFulcrum.Client.Diagnostics.Event.clientCallBegin, SwiftFulcrumDiagnostics.Event.clientCallBegin),
            (SwiftFulcrum.Client.Diagnostics.Event.clientCallSent, SwiftFulcrumDiagnostics.Event.clientCallSent),
            (SwiftFulcrum.Client.Diagnostics.Event.clientCallResponseDecoded, SwiftFulcrumDiagnostics.Event.clientCallResponseDecoded),
            (SwiftFulcrum.Client.Diagnostics.Event.clientCallTimeout, SwiftFulcrumDiagnostics.Event.clientCallTimeout),
            (SwiftFulcrum.Client.Diagnostics.Event.clientCallCancelled, SwiftFulcrumDiagnostics.Event.clientCallCancelled),
            (SwiftFulcrum.Client.Diagnostics.Event.clientCallFailed, SwiftFulcrumDiagnostics.Event.clientCallFailed),
            (SwiftFulcrum.Client.Diagnostics.Event.clientSubscribeBegin, SwiftFulcrumDiagnostics.Event.clientSubscribeBegin),
            (SwiftFulcrum.Client.Diagnostics.Event.clientSubscribeSent, SwiftFulcrumDiagnostics.Event.clientSubscribeSent),
            (SwiftFulcrum.Client.Diagnostics.Event.clientSubscribeInitialDecoded, SwiftFulcrumDiagnostics.Event.clientSubscribeInitialDecoded),
            (SwiftFulcrum.Client.Diagnostics.Event.clientSubscribeTimeout, SwiftFulcrumDiagnostics.Event.clientSubscribeTimeout),
            (SwiftFulcrum.Client.Diagnostics.Event.clientSubscribeCancelled, SwiftFulcrumDiagnostics.Event.clientSubscribeCancelled),
            (SwiftFulcrum.Client.Diagnostics.Event.clientSubscribeFailed, SwiftFulcrumDiagnostics.Event.clientSubscribeFailed),
            (SwiftFulcrum.Client.Diagnostics.Event.clientDiagnosticsUpdated, SwiftFulcrumDiagnostics.Event.clientDiagnosticsUpdated),
            (SwiftFulcrum.Client.Diagnostics.Event.clientSubscriptionsUpdated, SwiftFulcrumDiagnostics.Event.clientSubscriptionsUpdated),
            (SwiftFulcrum.Client.Diagnostics.Event.clientHeartbeatTimeout, SwiftFulcrumDiagnostics.Event.clientHeartbeatTimeout),
            (SwiftFulcrum.Client.Diagnostics.Event.clientReconnectRecoveryBegin, SwiftFulcrumDiagnostics.Event.clientReconnectRecoveryBegin),
            (SwiftFulcrum.Client.Diagnostics.Event.clientReconnectRecoverySucceeded, SwiftFulcrumDiagnostics.Event.clientReconnectRecoverySucceeded),
            (SwiftFulcrum.Client.Diagnostics.Event.clientReconnectRecoveryFailed, SwiftFulcrumDiagnostics.Event.clientReconnectRecoveryFailed),
            (SwiftFulcrum.Client.Diagnostics.Event.clientSubscriptionRestored, SwiftFulcrumDiagnostics.Event.clientSubscriptionRestored),
            (SwiftFulcrum.Client.Diagnostics.Event.clientSubscriptionRestoreFailed, SwiftFulcrumDiagnostics.Event.clientSubscriptionRestoreFailed),
            (SwiftFulcrum.Client.Diagnostics.Event.clientSubscriptionRemoved, SwiftFulcrumDiagnostics.Event.clientSubscriptionRemoved),
            (SwiftFulcrum.Client.Diagnostics.Event.clientSubscriptionAdded, SwiftFulcrumDiagnostics.Event.clientSubscriptionAdded),
            (SwiftFulcrum.Client.Diagnostics.Event.webSocketConnectBegin, SwiftFulcrumDiagnostics.Event.webSocketConnectBegin),
            (SwiftFulcrum.Client.Diagnostics.Event.webSocketConnectSucceeded, SwiftFulcrumDiagnostics.Event.webSocketConnectSucceeded),
            (SwiftFulcrum.Client.Diagnostics.Event.webSocketConnectTimeout, SwiftFulcrumDiagnostics.Event.webSocketConnectTimeout),
            (SwiftFulcrum.Client.Diagnostics.Event.webSocketConnectFailover, SwiftFulcrumDiagnostics.Event.webSocketConnectFailover),
            (SwiftFulcrum.Client.Diagnostics.Event.webSocketConnectFailoverExhausted, SwiftFulcrumDiagnostics.Event.webSocketConnectFailoverExhausted),
            (SwiftFulcrum.Client.Diagnostics.Event.webSocketDisconnect, SwiftFulcrumDiagnostics.Event.webSocketDisconnect),
            (SwiftFulcrum.Client.Diagnostics.Event.webSocketSendBegin, SwiftFulcrumDiagnostics.Event.webSocketSendBegin),
            (SwiftFulcrum.Client.Diagnostics.Event.webSocketSendSucceeded, SwiftFulcrumDiagnostics.Event.webSocketSendSucceeded),
            (SwiftFulcrum.Client.Diagnostics.Event.webSocketSendFailed, SwiftFulcrumDiagnostics.Event.webSocketSendFailed),
            (SwiftFulcrum.Client.Diagnostics.Event.webSocketReceiveMessage, SwiftFulcrumDiagnostics.Event.webSocketReceiveMessage),
            (SwiftFulcrum.Client.Diagnostics.Event.webSocketReceiveFailed, SwiftFulcrumDiagnostics.Event.webSocketReceiveFailed),
            (SwiftFulcrum.Client.Diagnostics.Event.webSocketReceiveReconnected, SwiftFulcrumDiagnostics.Event.webSocketReceiveReconnected),
            (SwiftFulcrum.Client.Diagnostics.Event.reconnectAttempt, SwiftFulcrumDiagnostics.Event.reconnectAttempt),
            (SwiftFulcrum.Client.Diagnostics.Event.reconnectSucceeded, SwiftFulcrumDiagnostics.Event.reconnectSucceeded),
            (SwiftFulcrum.Client.Diagnostics.Event.reconnectFailed, SwiftFulcrumDiagnostics.Event.reconnectFailed),
            (SwiftFulcrum.Client.Diagnostics.Event.reconnectMaxAttempts, SwiftFulcrumDiagnostics.Event.reconnectMaxAttempts)
        ]

        for (publicEvent, internalEvent) in eventMappings {
            #expect(publicEvent == internalEvent)
        }
    }

    @Test("Diagnostics error code catalog maps known failures")
    func mapDiagnosticsErrorCodeCatalogToKnownFailures() {
        let mappings = [
            (
                SwiftFulcrumDiagnostics.errorCode(for: SwiftFulcrum.Client.Error.client(.cancelled)),
                SwiftFulcrum.Client.Diagnostics.ErrorCode.clientCancelled
            ),
            (
                SwiftFulcrumDiagnostics.errorCode(for: SwiftFulcrum.Client.Error.client(.timeout(.seconds(1)))),
                SwiftFulcrum.Client.Diagnostics.ErrorCode.clientTimeout
            ),
            (
                SwiftFulcrumDiagnostics.errorCode(for: SwiftFulcrum.Client.Error.coding(.decode(nil))),
                SwiftFulcrum.Client.Diagnostics.ErrorCode.jsonRPCDecodeFailed
            ),
            (
                SwiftFulcrumDiagnostics.errorCode(for: SwiftFulcrum.Client.Error.rpc(.init(id: nil, code: 1, message: "server message"))),
                SwiftFulcrum.Client.Diagnostics.ErrorCode.jsonRPCServerError
            ),
            (
                SwiftFulcrumDiagnostics.errorCode(for: SwiftFulcrum.Client.Error.transport(.connectionClosed(.goingAway, "server reason"))),
                SwiftFulcrum.Client.Diagnostics.ErrorCode.webSocketConnectionClosed
            ),
            (
                SwiftFulcrumDiagnostics.errorCode(for: SwiftFulcrum.Client.Error.transport(.heartbeatTimeout)),
                SwiftFulcrum.Client.Diagnostics.ErrorCode.webSocketHeartbeatTimeout
            ),
            (
                SwiftFulcrumDiagnostics.errorCode(for: JSONRPCCodec.Error.decodingFailure(reason: .unexpectedFormat, data: Data([0x01]), description: "payload detail")),
                SwiftFulcrum.Client.Diagnostics.ErrorCode.jsonRPCUnexpectedFormat
            )
        ]

        for (actual, expected) in mappings {
            #expect(actual == expected)
        }
    }

    @Test("JSON-RPC request encoding records a traced diagnostics event")
    func requestEncodingRecordsDiagnosticsEvent() throws {
        try withDiagnosticsCapture {
            let requestID = UUID()
            let request = SwiftFulcrum.RPC.Method.server(.ping).createRequest(with: requestID)
            let payload = try #require(request.data)

            let traceID = SwiftFulcrumDiagnostics.traceID(for: requestID)
            let record = try #require(diagnosticRecord(named: SwiftFulcrum.Client.Diagnostics.Event.jsonRPCRequestEncoded, traceID: traceID))
            #expect(record.category == SwiftFulcrum.Client.Diagnostics.Category.jsonRPC)
            #expect(record.traceID == traceID)
            #expect(field("method_path", in: record)?.value == "server.ping")
            #expect(field("request_id", in: record)?.value == requestID.uuidString)
            #expect(field("byte_count", in: record)?.value == String(payload.count))
        }
    }

    @Test("JSON-RPC request encoding failures record a stable error code")
    func recordStableErrorCodeForRequestEncodingFailure() throws {
        try withDiagnosticsCapture {
            let requestID = UUID()
            let request = FulcrumRequest(
                id: requestID,
                method: SwiftFulcrum.RPC.Method.server(.ping),
                params: ThrowingParameters()
            )
            #expect(request.data == nil)

            let traceID = SwiftFulcrumDiagnostics.traceID(for: requestID)
            let record = try #require(diagnosticRecord(named: SwiftFulcrum.Client.Diagnostics.Event.jsonRPCRequestEncodeFailed, traceID: traceID))
            #expect(record.category == SwiftFulcrum.Client.Diagnostics.Category.jsonRPC)
            #expect(field("method_path", in: record)?.value == "server.ping")
            #expect(field(SwiftFulcrum.Client.Diagnostics.Field.errorCode, in: record)?.value == SwiftFulcrum.Client.Diagnostics.ErrorCode.jsonRPCEncodeFailed)
            #expect(field("error_message", in: record)?.value == "<redacted>")
        }
    }

    @Test("JSON-RPC response decoding records success and redacted failures")
    func responseDecodingRecordsDiagnosticsEvents() throws {
        try withDiagnosticsCapture {
            let requestID = UUID()
            let successPayload = try jsonData(["jsonrpc": "2.0", "id": requestID.uuidString, "result": "ok"])
            let decoded = try successPayload.decode(String.self, context: .init(methodPath: "server.banner"))
            #expect(decoded == "ok")

            let traceID = SwiftFulcrumDiagnostics.traceID(for: requestID)
            let successRecord = try #require(diagnosticRecord(named: SwiftFulcrumDiagnostics.Event.jsonRPCResponseDecoded, traceID: traceID))
            #expect(successRecord.category == SwiftFulcrumDiagnostics.Category.jsonRPC)
            #expect(successRecord.traceID == traceID)
            #expect(field("method_hint", in: successRecord)?.value == "server.banner")
            #expect(field("byte_count", in: successRecord)?.value == String(successPayload.count))

            OpalDiagnostics.clearRecentRecords()

            let failurePayload = try jsonData(["jsonrpc": "2.0", "id": requestID.uuidString, "result": "not-an-int"])
            #expect(throws: DecodingError.self) {
                _ = try failurePayload.decode(Int.self, context: .init(methodPath: "server.banner"))
            }

            let failureRecord = try #require(diagnosticRecord(named: SwiftFulcrumDiagnostics.Event.jsonRPCResponseDecodeFailed, traceID: traceID))
            #expect(failureRecord.category == SwiftFulcrumDiagnostics.Category.jsonRPC)
            #expect(failureRecord.traceID == traceID)
            #expect(field("method_hint", in: failureRecord)?.value == "server.banner")
            #expect(field(SwiftFulcrum.Client.Diagnostics.Field.errorCode, in: failureRecord)?.value == SwiftFulcrum.Client.Diagnostics.ErrorCode.jsonRPCDecodeFailed)
            #expect(field("error_type", in: failureRecord)?.privacy == .public)
            #expect(field("error_message", in: failureRecord)?.value == "<redacted>")
        }
    }

    @Test("JSON-RPC error responses are not recorded as decode failures")
    func rpcErrorResponsesAreNotRecordedAsDecodeFailures() throws {
        try withDiagnosticsCapture {
            let requestID = UUID()
            let errorPayload = try jsonData([
                "jsonrpc": "2.0",
                "id": requestID.uuidString,
                "error": ["code": 1, "message": "server rejected request"]
            ])

            #expect(throws: SwiftFulcrum.Client.Error.self) {
                _ = try errorPayload.decode(String.self, context: .init(methodPath: "server.banner"))
            }

            let traceID = SwiftFulcrumDiagnostics.traceID(for: requestID)
            let decodedRecord = try #require(diagnosticRecord(named: SwiftFulcrumDiagnostics.Event.jsonRPCResponseDecoded, traceID: traceID))
            #expect(decodedRecord.category == SwiftFulcrumDiagnostics.Category.jsonRPC)
            #expect(field("method_hint", in: decodedRecord)?.value == "server.banner")
            #expect(field(SwiftFulcrum.Client.Diagnostics.Field.errorCode, in: decodedRecord)?.value == SwiftFulcrum.Client.Diagnostics.ErrorCode.jsonRPCServerError)
            #expect(field("error_message", in: decodedRecord) == nil)
            #expect(OpalDiagnostics.recentRecords(matching: .init(event: SwiftFulcrumDiagnostics.Event.jsonRPCResponseDecodeFailed)).isEmpty)
        }
    }

    @Test("Network call records begin, sent, and decoded diagnostics")
    func networkCallRecordsRequestLifecycleDiagnostics() async throws {
        try await withDiagnosticsCapture {
            let transport = TransportTestActor()
            let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
            let method = SwiftFulcrum.RPC.Method.server(
                .version(clientName: "diagnostics-test", protocolNegotiation: SwiftFulcrum.Client.Configuration.ProtocolNegotiation().makeArgument())
            )

            let callTask = Task<(UUID, SwiftFulcrum.Response.Server.Version), Swift.Error> {
                try await client.call(method: method)
            }

            let outgoingMessage = await transport.dequeueOutgoing()
            let outgoingObject = try TransportTestActor.decodeJSONObject(from: outgoingMessage)
            let requestID = try requestIdentifier(from: outgoingObject)
            let responsePayload = try jsonData(
                ["jsonrpc": "2.0", "id": requestID.uuidString, "result": ["Fulcrum", "1.5.3"]]
            )
            _ = await client.handleMessage(.data(responsePayload))

            let (returnedID, response) = try await callTask.value
            #expect(returnedID == requestID)
            #expect(response.serverVersion == "Fulcrum")

            let traceID = SwiftFulcrumDiagnostics.traceID(for: requestID)
            #expect(diagnosticRecord(named: SwiftFulcrumDiagnostics.Event.clientCallBegin, traceID: traceID) != nil)
            #expect(diagnosticRecord(named: SwiftFulcrumDiagnostics.Event.clientCallSent, traceID: traceID) != nil)
            #expect(diagnosticRecord(named: SwiftFulcrumDiagnostics.Event.clientCallResponseDecoded, traceID: traceID) != nil)
            #expect(diagnosticRecord(named: SwiftFulcrumDiagnostics.Event.jsonRPCResponseDecoded, traceID: traceID) != nil)
        }
    }

    @Test("WebSocket lifecycle records public fields and redacts private fields", .timeLimit(.minutes(1)))
    func webSocketLifecycleRecordsRedactedDiagnostics() async throws {
        try await withDiagnosticsCapture {
            let webSocket = WebSocketConnection(url: URL(string: "wss://fulcrum.example.invalid")!)
            await webSocket.disconnect(with: "local shutdown reason")

            let disconnectRecord = try #require(diagnosticRecord(named: SwiftFulcrumDiagnostics.Event.webSocketDisconnect))
            #expect(disconnectRecord.category == SwiftFulcrumDiagnostics.Category.webSocket)
            #expect(field("close_code", in: disconnectRecord)?.value == String(URLSessionWebSocketTask.CloseCode.goingAway.rawValue))
            #expect(field("endpoint_url", in: disconnectRecord)?.value == "<redacted>")
            #expect(field("reason", in: disconnectRecord)?.value == "<redacted>")

            OpalDiagnostics.clearRecentRecords()

            do {
                try await webSocket.send(data: Data([0x01, 0x02, 0x03]))
                Issue.record("Expected send without an active socket task to fail.")
            } catch {
                let sendFailureRecord = try #require(diagnosticRecord(named: SwiftFulcrumDiagnostics.Event.webSocketSendFailed))
                #expect(field("payload_type", in: sendFailureRecord)?.value == "data")
                #expect(field("byte_count", in: sendFailureRecord)?.value == "3")
                #expect(field("error_type", in: sendFailureRecord)?.privacy == .public)
            }

            let session = await webSocket.session
            session.invalidateAndCancel()
        }
    }

    @Test("Task cancellation records one request diagnostics failure", .timeLimit(.minutes(1)))
    func taskCancellationRecordsOneRequestDiagnosticsFailure() async throws {
        await withDiagnosticsCapture {
            let transport = TransportTestActor()
            await transport.configureOutgoingSendPaused(true)
            let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
            let method = SwiftFulcrum.RPC.Method.server(
                .version(clientName: "diagnostics-test", protocolNegotiation: SwiftFulcrum.Client.Configuration.ProtocolNegotiation().makeArgument())
            )

            let callTask = Task<SwiftFulcrum.Client.Error, Never> {
                do {
                    let _: (UUID, SwiftFulcrum.Response.Server.Version) = try await client.call(
                        method: method,
                        options: .init(timeout: .seconds(30))
                    )
                    Issue.record("call() should throw cancelled when the calling task is cancelled.")
                    return .client(.unknown(nil))
                } catch let error as SwiftFulcrum.Client.Error {
                    return error
                } catch {
                    Issue.record("Unexpected non-SwiftFulcrum.Client error: \(error)")
                    return .client(.unknown(error))
                }
            }

            let didPauseSend = await waitUntil(timeout: .seconds(2)) {
                await transport.makePendingOutgoingSendCount() == 1
            }
            #expect(didPauseSend)

            callTask.cancel()
            await transport.configureOutgoingSendPaused(false)

            let error = await callTask.value
            if case .client(.cancelled) = error {
            } else {
                Issue.record("Expected cancellation error, got \(error).")
            }
            try? await Task.sleep(for: .milliseconds(50))

            let records = OpalDiagnostics.recentRecords(
                matching: .init(event: SwiftFulcrumDiagnostics.Event.clientCallCancelled)
            )
            #expect(records.count == 1)
        }
    }

    private static let diagnosticsConfiguration = OpalDiagnostics.Configuration(
        minimumLevel: .debug,
        categoryFilter: .enabledIncludingSubcategories([SwiftFulcrumDiagnostics.Category.fulcrum]),
        bufferPolicy: .enabled(capacity: 10_000)
    )

    private func withDiagnosticsCapture<Success>(_ operation: () throws -> Success) rethrows -> Success {
        try OpalDiagnostics.withConfiguration(Self.diagnosticsConfiguration) {
            OpalDiagnostics.clearRecentRecords()
            return try operation()
        }
    }

    private func withDiagnosticsCapture<Success>(_ operation: () async throws -> Success) async rethrows -> Success {
        try await OpalDiagnostics.withConfiguration(Self.diagnosticsConfiguration) {
            OpalDiagnostics.clearRecentRecords()
            return try await operation()
        }
    }

    private func diagnosticRecord(
        named event: OpalDiagnostics.Event,
        traceID: OpalDiagnostics.TraceID? = nil
    ) -> OpalDiagnostics.Record? {
        OpalDiagnostics.recentRecords(matching: .init(traceID: traceID, event: event)).first
    }

    private func field(_ name: String, in record: OpalDiagnostics.Record) -> OpalDiagnostics.Field? {
        record.fields.first { $0.name == name }
    }

    private func jsonData(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    private func requestIdentifier(from object: [String: Any]) throws -> UUID {
        let rawIdentifier = try #require(object["id"] as? String)
        return try #require(UUID(uuidString: rawIdentifier))
    }

    private func waitUntil(
        timeout: Duration,
        pollingInterval: Duration = .milliseconds(25),
        _ condition: @Sendable @escaping () async -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while clock.now < deadline {
            if await condition() {
                return true
            }
            try? await Task.sleep(for: pollingInterval)
        }

        return await condition()
    }

    private struct ThrowingParameters: Encodable {
        func encode(to encoder: Encoder) throws {
            throw EncodingError.invalidValue(
                "secret",
                .init(codingPath: encoder.codingPath, debugDescription: "do not expose this")
            )
        }
    }
}
