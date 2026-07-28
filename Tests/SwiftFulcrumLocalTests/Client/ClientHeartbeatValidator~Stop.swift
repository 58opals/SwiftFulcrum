// ClientHeartbeatValidator~Stop.swift

import Foundation
import Testing
@testable import SwiftFulcrum

extension ClientHeartbeatValidator {
    @Test(
        "stop() cancels heartbeat before disconnect can trigger reconnect",
        .timeLimit(.minutes(1))
    )
    func stopCancelsHeartbeatBeforeDisconnect() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(
            transport: transport,
            heartbeatInterval: .milliseconds(20),
            heartbeatTimeout: .seconds(30),
            protocolNegotiation: .init()
        )

        try await startAndNegotiate(client: client, transport: transport)

        let ping = try TransportTestActor.decodeJSONObject(
            from: await transport.dequeueOutgoing()
        )
        #expect(
            ping["method"] as? String
                == SwiftFulcrum.RPC.Method.server(.ping).path
        )

        await transport.configureDisconnectPaused(true)
        let stopTask = Task {
            await client.stop()
        }

        let didBeginDisconnect = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingDisconnectCount() == 1
        }
        #expect(didBeginDisconnect)
        #expect(await client.isRPCHeartbeatStoppedForTesting)

        await transport.failIncomingStreamForHeartbeatStopTest()
        let didStopReceiving = await waitUntil(timeout: .seconds(2)) {
            await client.isReceiveTaskStoppedForTesting
        }
        #expect(didStopReceiving)

        let didReconnect = await waitUntil(timeout: .milliseconds(250)) {
            await transport.makeReconnectAttempts() > 0
        }
        #expect(didReconnect == false)

        await transport.configureDisconnectPaused(false)
        await stopTask.value
        #expect(await transport.connectionState == .disconnected)
    }

    @Test(
        "stop() drains heartbeat started by a cancelled startup",
        .timeLimit(.minutes(1))
    )
    func stopDrainsHeartbeatStartedByCancelledStartup() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(
            transport: transport,
            heartbeatInterval: .seconds(30),
            heartbeatTimeout: .seconds(30),
            protocolNegotiation: .init()
        )
        let startTask = Task {
            try await client.start()
        }

        let version = try TransportTestActor.decodeJSONObject(
            from: await transport.dequeueOutgoing()
        )
        let versionIdentifier = try #require(version["id"] as? String)
        await transport.enqueueIncoming(
            .data(
                try TransportTestActor.encodeResponsePayload(
                    identifier: versionIdentifier,
                    result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
                )
            )
        )

        let features = try TransportTestActor.decodeJSONObject(
            from: await transport.dequeueOutgoing()
        )
        let featuresIdentifier = try #require(features["id"] as? String)
        await transport.pauseReconnectSuccessRead(afterUnpausedReads: 1)
        await transport.enqueueIncoming(
            .data(
                try TransportTestActor.encodeResponsePayload(
                    identifier: featuresIdentifier,
                    result: [
                        "genesis_hash": String(repeating: "0", count: 64),
                        "hash_function": "sha256",
                        "server_version": "SwiftFulcrum.Client 2.0",
                        "protocol_max": "1.6.0",
                        "protocol_min": "1.4.0"
                    ]
                )
            )
        )

        let didPauseStartup = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingReconnectSuccessReadCount() == 1
        }
        #expect(didPauseStartup)

        let stopTask = Task {
            await client.stop()
        }
        let didBeginDisconnect = await waitUntil(timeout: .seconds(2)) {
            await transport.connectionState == .disconnected
        }
        #expect(didBeginDisconnect)

        await transport.resumePendingReconnectSuccessReads()
        await stopTask.value
        _ = await startTask.result

        #expect(await client.isRPCHeartbeatStoppedForTesting)
        #expect(await transport.connectionState == .disconnected)
        #expect(await transport.makeReconnectAttempts() == 0)
    }
}
