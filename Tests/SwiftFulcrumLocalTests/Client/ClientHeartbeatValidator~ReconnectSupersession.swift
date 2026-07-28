// ClientHeartbeatValidator~ReconnectSupersession.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientHeartbeatValidator {
    @Test(
        "reconnect-superseded heartbeat awaits recovery without reconnecting",
        .timeLimit(.minutes(1))
    )
    func awaitRecoveryWhenReconnectSupersedesHeartbeat() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(
            transport: transport,
            heartbeatInterval: .milliseconds(20),
            heartbeatTimeout: .seconds(2),
            protocolNegotiation: .init()
        )
        try await startAndNegotiate(client: client, transport: transport)

        let pingRequest = try TransportTestActor.decodeJSONObject(
            from: await transport.dequeueOutgoing()
        )
        #expect(pingRequest["method"] as? String == "server.ping")

        try await transport.reconnect(with: nil)
        await transport.configureConnectionState(.connected)
        await transport.enqueueLifecycleEvent(.connected(isReconnect: true))

        let didBeginRecovery = await waitUntil(timeout: .seconds(2)) {
            await client.reconnectRecoveryState.recoveryTask != nil
        }
        try #require(didBeginRecovery)
        try await completeHeartbeatRecovery(on: transport)

        let recoveryTask = try #require(
            await client.reconnectRecoveryState.recoveryTask
        )
        try await recoveryTask.value
        try await Task.sleep(for: .milliseconds(50))
        #expect(await transport.makeReconnectAttempts() == 1)

        await client.stop()
    }

    private func completeHeartbeatRecovery(
        on transport: TransportTestActor
    ) async throws {
        let versionRequest = try TransportTestActor.decodeJSONObject(
            from: await transport.dequeueOutgoing()
        )
        let versionIdentifier = try #require(
            versionRequest["id"] as? String
        )
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try TransportTestActor.decodeJSONObject(
            from: await transport.dequeueOutgoing()
        )
        let featuresIdentifier = try #require(
            featuresRequest["id"] as? String
        )
        let featuresPayload = try TransportTestActor.encodeResponsePayload(
            identifier: featuresIdentifier,
            result: [
                "genesis_hash": String(repeating: "0", count: 64),
                "hash_function": "sha256",
                "server_version": "SwiftFulcrum.Client 2.0",
                "protocol_max": "1.6.0",
                "protocol_min": "1.4.0"
            ]
        )
        await transport.enqueueIncoming(.data(featuresPayload))
    }
}
