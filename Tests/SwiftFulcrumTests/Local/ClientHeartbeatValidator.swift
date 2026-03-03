import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientHeartbeatValidator {
    @Test("Heartbeat timeout triggers reconnect attempt", .timeLimit(.minutes(1)))
    func heartbeatTimeoutTriggersReconnectAttempt() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(
            transport: transport,
            heartbeatInterval: .milliseconds(20),
            heartbeatTimeout: .milliseconds(20),
            protocolNegotiation: .init()
        )

        try await startAndNegotiate(client: client, transport: transport)
        try await Task.sleep(for: .milliseconds(120))

        let reconnectAttempts = await transport.makeReconnectAttempts()
        #expect(reconnectAttempts > 0)

        await client.stop()
    }

    @Test("Heartbeat reconnect failure fails inflight unary calls with heartbeat timeout", .timeLimit(.minutes(1)))
    func failInflightUnaryCallsWhenHeartbeatReconnectFails() async throws {
        let transport = TransportTestActor()
        await transport.configureReconnectFailure(FulcrumClient.Error.transport(.reconnectFailed))

        let client = FulcrumNetworkClient(
            transport: transport,
            heartbeatInterval: .milliseconds(20),
            heartbeatTimeout: .milliseconds(20),
            protocolNegotiation: .init()
        )
        try await startAndNegotiate(client: client, transport: transport)

        let callTask = Task {
            do {
                let _: (UUID, FulcrumResponse.ResultModel.Blockchain.Headers.GetTip) =
                    try await client.call(method: .blockchain(.headers(.getTip)))
                Issue.record("Expected inflight unary to fail when heartbeat reconnect fails")
            } catch let error as FulcrumClient.Error {
                guard case .transport(.heartbeatTimeout) = error else {
                    Issue.record("Expected heartbeat timeout error, got \(error)")
                    return
                }
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        let request = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        #expect(request["method"] as? String == FulcrumMethodRequest.blockchain(.headers(.getTip)).path)

        await callTask.value
        #expect(await transport.makeReconnectAttempts() > 0)

        await client.stop()
    }
}

private extension ClientHeartbeatValidator {
    func startAndNegotiate(client: FulcrumNetworkClient, transport: TransportTestActor) async throws {
        let startTask = Task { try await client.start() }

        let versionObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let versionIdentifier = try #require(versionObject["id"] as? String)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["FulcrumClient 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let featuresIdentifier = try #require(featuresObject["id"] as? String)
        let featuresPayload = try TransportTestActor.encodeResponsePayload(
            identifier: featuresIdentifier,
            result: [
                "genesis_hash": String(repeating: "0", count: 64),
                "hash_function": "sha256",
                "server_version": "FulcrumClient 2.0",
                "protocol_max": "1.6.0",
                "protocol_min": "1.4.0"
            ]
        )
        await transport.enqueueIncoming(.data(featuresPayload))

        _ = try await startTask.value
    }
}
