// SwiftFulcrumDiagnosticsValidator.swift

import Foundation
import OpalDiagnostics
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.serialized, .tags(.local))
struct SwiftFulcrumDiagnosticsValidator {
    @Test("JSON-RPC request encoding records a traced diagnostics event")
    func requestEncodingRecordsDiagnosticsEvent() throws {
        try withDiagnosticsCapture {
            let requestID = UUID()
            let request = SwiftFulcrum.RPC.Method.server(.ping).createRequest(with: requestID)
            let payload = try #require(request.data)

            let traceID = SwiftFulcrumDiagnostics.traceID(for: requestID)
            let record = try #require(diagnosticRecord(named: SwiftFulcrumDiagnostics.Event.jsonRPCRequestEncoded, traceID: traceID))
            #expect(record.category == SwiftFulcrumDiagnostics.Category.jsonRPC)
            #expect(record.traceID == traceID)
            #expect(field("method_path", in: record)?.value == "server.ping")
            #expect(field("request_id", in: record)?.value == requestID.uuidString)
            #expect(field("byte_count", in: record)?.value == String(payload.count))
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
}
