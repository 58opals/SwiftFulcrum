// FulcrumClientLifecycleValidator~ReconnectFinalization.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test(
        "manual reconnect recovers success arriving during final state recording",
        .timeLimit(.minutes(1))
    )
    func recoverReconnectSuccessDuringManualFinalization() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client
        let reconnectTask = Task {
            try await fulcrum.reconnect()
        }

        let versionRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        let versionIdentifier = try extractRequestIdentifier(
            from: versionRequest
        )
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["Generation A", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        let featuresIdentifier = try extractRequestIdentifier(
            from: featuresRequest
        )
        try await Task.sleep(for: .milliseconds(25))
        await transport.pauseEndpointRead(afterUnpausedReads: 1)
        let featuresPayload = try TransportTestActor.encodeResponsePayload(
            identifier: featuresIdentifier,
            result: makeReconnectFeatures(serverVersion: "Generation A")
        )
        await transport.enqueueIncoming(.data(featuresPayload))

        var didPauseFinalStateRecording = await waitUntil(
            timeout: .seconds(2)
        ) {
            await transport.makePendingEndpointReadCount() == 1
        }
        try #require(didPauseFinalStateRecording)

        let firstReconnectSuccessCount = await transport.reconnectSuccesses
        while await networkClient.recoveredReconnectSuccessCount
                != firstReconnectSuccessCount {
            await transport.resumePendingEndpointReads(pausingNextRead: true)
            didPauseFinalStateRecording = await waitUntil(
                timeout: .seconds(2)
            ) {
                await transport.makePendingEndpointReadCount() == 1
            }
            try #require(didPauseFinalStateRecording)
        }
        #expect(
            await networkClient.recoveredReconnectSuccessCount
                == firstReconnectSuccessCount
        )

        try await transport.reconnect(with: nil)
        await transport.configureConnectionState(.connected)
        let secondReconnectSuccessCount = await transport.reconnectSuccesses
        await networkClient.handleSuccessfulTransportReconnect()
        #expect(
            await networkClient.pendingManualReconnectRecoverySuccessCount
                == secondReconnectSuccessCount
        )

        await transport.resumePendingEndpointReads()
        try await completeProtocolNegotiation(on: transport)
        try await reconnectTask.value

        #expect(
            await networkClient.recoveredReconnectSuccessCount
                == secondReconnectSuccessCount
        )
        #expect(
            await networkClient.pendingManualReconnectRecoverySuccessCount
                == nil
        )
        await fulcrum.stop()
    }

    private func makeReconnectFeatures(
        serverVersion: String
    ) -> [String: Any] {
        [
            "genesis_hash": String(repeating: "0", count: 64),
            "hash_function": "sha256",
            "server_version": serverVersion,
            "protocol_max": "1.6.0",
            "protocol_min": "1.4.0"
        ]
    }
}
