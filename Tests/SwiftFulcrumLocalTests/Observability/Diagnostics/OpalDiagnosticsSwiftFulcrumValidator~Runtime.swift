// OpalDiagnosticsSwiftFulcrumValidator~Runtime.swift

import Foundation
import OpalDiagnostics
import Testing
@testable import SwiftFulcrum

extension OpalDiagnosticsSwiftFulcrumValidator {
    @Test("Network call records begin, sent, and decoded diagnostics")
    func validateNetworkCallRecordsRequestLifecycleDiagnostics() async throws {
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
            let requestID = try makeRequestIdentifier(from: outgoingObject)
            let responsePayload = try makeJSONData(
                ["jsonrpc": "2.0", "id": requestID.uuidString, "result": ["Fulcrum", "1.5.3"]]
            )
            _ = await client.handleMessage(.data(responsePayload))

            let (returnedID, response) = try await callTask.value
            #expect(returnedID == requestID)
            #expect(response.serverVersion == "Fulcrum")

            let traceID = OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestID)
            #expect(findDiagnosticRecord(named: .swiftFulcrumClientCallBegin, traceID: traceID) != nil)
            #expect(findDiagnosticRecord(named: .swiftFulcrumClientCallSent, traceID: traceID) != nil)
            #expect(findDiagnosticRecord(named: .swiftFulcrumClientCallResponseDecoded, traceID: traceID) != nil)
            #expect(findDiagnosticRecord(named: .swiftFulcrumJSONRPCResponseDecoded, traceID: traceID) != nil)
        }
    }

    @Test("Unroutable response decode failures record diagnostics")
    func validateUnroutableResponseDecodeFailuresRecordDiagnostics() async throws {
        try await withDiagnosticsCapture {
            let transport = TransportTestActor()
            let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())

            let malformedPayload = Data([0x01])
            let handledCount = await client.handleMessage(.data(malformedPayload))
            #expect(handledCount == nil)

            let failureRecord = try #require(findDiagnosticRecord(named: .swiftFulcrumJSONRPCResponseDecodeFailed))
            #expect(failureRecord.category == .swiftFulcrumJSONRPC)
            #expect(findField("byte_count", in: failureRecord)?.value == String(malformedPayload.count))
            #expect(findField(OpalDiagnostics.Field.swiftFulcrumErrorCodeName, in: failureRecord)?.value == "jsonrpc.decode_failed")
            #expect(findField("error_message", in: failureRecord)?.value == "<redacted>")
        }
    }

    @Test("Manual reconnect failure records recovery diagnostics", .timeLimit(.minutes(1)))
    func validateManualReconnectFailureRecordsRecoveryDiagnostics() async throws {
        try await withDiagnosticsCapture {
            let transport = TransportTestActor()
            let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())

            try await startAndCompleteProtocolNegotiation(client: client, transport: transport)

            await transport.configureReconnectFailure(SwiftFulcrum.Client.Error.transport(.reconnectFailed))

            do {
                try await client.reconnect()
                Issue.record("reconnect() should throw the configured transport failure.")
            } catch {
                let failureRecord = try #require(findDiagnosticRecord(named: .swiftFulcrumClientReconnectRecoveryFailed))
                #expect(failureRecord.category == .swiftFulcrumReconnect)
                #expect(findField("reconnect_attempts", in: failureRecord)?.value == "1")
                #expect(findField("reconnect_successes", in: failureRecord)?.value == "0")
                #expect(findField(OpalDiagnostics.Field.swiftFulcrumErrorCodeName, in: failureRecord)?.value == "websocket.reconnect_failed")
            }

            await client.stop()
        }
    }

    @Test("Heartbeat timeout records transport diagnostics", .timeLimit(.minutes(1)))
    func validateHeartbeatTimeoutRecordsTransportDiagnostics() async throws {
        try await withDiagnosticsCapture {
            let transport = TransportTestActor()
            let client = FulcrumNetworkClient(
                transport: transport,
                heartbeatInterval: .milliseconds(20),
                heartbeatTimeout: .milliseconds(20),
                protocolNegotiation: .init()
            )

            try await startAndCompleteProtocolNegotiation(client: client, transport: transport)

            let didRecordTimeout = await waitUntil(timeout: .seconds(2)) {
                findDiagnosticRecord(named: .swiftFulcrumClientHeartbeatTimeout) != nil
            }
            #expect(didRecordTimeout)

            let timeoutRecord = try #require(findDiagnosticRecord(named: .swiftFulcrumClientHeartbeatTimeout))
            #expect(timeoutRecord.category == .fulcrum)
            #expect(findField("endpoint_url", in: timeoutRecord)?.value == "<redacted>")
            #expect(findField("reconnect_attempts", in: timeoutRecord)?.value == "0")
            #expect(findField("reconnect_successes", in: timeoutRecord)?.value == "0")
            #expect(findField(OpalDiagnostics.Field.swiftFulcrumErrorCodeName, in: timeoutRecord)?.value == "client.timeout")

            await client.stop()
        }
    }

    @Test("Reconnect exhaustion records attempt counters", .timeLimit(.minutes(1)))
    func validateReconnectExhaustionRecordsAttemptCounters() async throws {
        try await withDiagnosticsCapture {
            let configuration = WebSocketConnection.Reconnector.Configuration(
                maximumReconnectionAttempts: 1,
                reconnectionDelay: 0.01,
                maximumDelay: 0.01,
                jitterRange: 1.0 ... 1.0
            )
            let unreachable = URL(string: "wss://127.0.0.1:9")!
            let webSocket = WebSocketConnection(
                url: unreachable,
                configuration: .init(serverCatalogLoader: .makeConstant([unreachable])),
                reconnectConfiguration: configuration,
                connectionTimeout: 0.01,
                sleep: { _ in try Task.checkCancellation() },
                jitter: { _ in 1 }
            )

            do {
                try await webSocket.reconnector.attemptReconnection(
                    for: webSocket,
                    shouldCancelReceiver: false,
                    isInitialConnection: false
                )
                Issue.record("Reconnection should exhaust against an unreachable endpoint.")
            } catch {
                let attemptRecord = try #require(findDiagnosticRecord(named: .swiftFulcrumReconnectAttempt))
                #expect(findField("reconnect_attempts", in: attemptRecord)?.value == "1")
                #expect(findField("reconnect_successes", in: attemptRecord)?.value == "0")
                #expect(findField("candidate_url", in: attemptRecord)?.value == "<redacted>")

                let exhaustedRecord = try #require(findDiagnosticRecord(named: .swiftFulcrumReconnectMaxAttempts))
                #expect(findField("reconnect_attempts", in: exhaustedRecord)?.value == "1")
                #expect(findField("reconnect_successes", in: exhaustedRecord)?.value == "0")
                #expect(findField("endpoint_url", in: exhaustedRecord)?.value == "<redacted>")
            }

            await webSocket.disconnect(with: "test teardown")
        }
    }

    @Test("WebSocket lifecycle records public fields and redacts private fields", .timeLimit(.minutes(1)))
    func validateWebSocketLifecycleRecordsRedactedDiagnostics() async throws {
        try await withDiagnosticsCapture {
            let webSocket = WebSocketConnection(url: URL(string: "wss://fulcrum.example.invalid")!)
            await webSocket.disconnect(with: "local shutdown reason")

            let disconnectRecord = try #require(findDiagnosticRecord(named: .swiftFulcrumWebSocketDisconnect))
            #expect(disconnectRecord.category == .swiftFulcrumWebSocket)
            #expect(findField("close_code", in: disconnectRecord)?.value == String(URLSessionWebSocketTask.CloseCode.goingAway.rawValue))
            #expect(findField("endpoint_url", in: disconnectRecord)?.value == "<redacted>")
            #expect(findField("reason", in: disconnectRecord)?.value == "<redacted>")

            OpalDiagnostics.clearRecentRecords()

            do {
                try await webSocket.send(data: Data([0x01, 0x02, 0x03]))
                Issue.record("Expected send without an active socket task to fail.")
            } catch {
                let sendFailureRecord = try #require(findDiagnosticRecord(named: .swiftFulcrumWebSocketSendFailed))
                #expect(findField("payload_type", in: sendFailureRecord)?.value == "data")
                #expect(findField("byte_count", in: sendFailureRecord)?.value == "3")
                #expect(findField("error_type", in: sendFailureRecord)?.privacy == .public)
            }

            let session = await webSocket.session
            session.invalidateAndCancel()
        }
    }

    @Test("Task cancellation records one request diagnostics failure", .timeLimit(.minutes(1)))
    func validateTaskCancellationRecordsOneRequestDiagnosticsFailure() async throws {
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
                matching: .init(event: .swiftFulcrumClientCallCancelled)
            )
            #expect(records.count == 1)
        }
    }
}
