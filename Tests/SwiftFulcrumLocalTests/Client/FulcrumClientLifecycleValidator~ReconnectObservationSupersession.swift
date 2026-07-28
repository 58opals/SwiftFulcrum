// FulcrumClientLifecycleValidator~ReconnectObservationSupersession.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("new reconnect supersedes recovery waiting on a lost response", .timeLimit(.minutes(1)))
    func supersedeLostResponseRecoveryWithNewReconnect() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client

        try await transport.reconnect(with: nil)
        await transport.enqueueLifecycleEvent(.connected(isReconnect: true))
        let firstVersionRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(firstVersionRequest["method"] as? String == "server.version")

        let firstRecoveryTask = try #require(
            await networkClient.reconnectRecoveryState.recoveryTask
        )

        await transport.enqueueLifecycleEvent(
            .disconnected(code: .goingAway, reason: "replacement reconnect")
        )
        try await transport.reconnect(with: nil)
        await transport.enqueueLifecycleEvent(.connected(isReconnect: true))

        let replacementVersionRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(replacementVersionRequest["method"] as? String == "server.version")

        let replacementRecoveryTask = try #require(
            await networkClient.reconnectRecoveryState.recoveryTask
        )
        let replacementVersionIdentifier = try extractRequestIdentifier(
            from: replacementVersionRequest
        )
        let replacementVersionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: replacementVersionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(replacementVersionPayload))

        let featuresRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        let featuresIdentifier = try extractRequestIdentifier(from: featuresRequest)
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
        try await replacementRecoveryTask.value

        await #expect(throws: CancellationError.self) {
            try await firstRecoveryTask.value
        }

        #expect(await networkClient.reconnectRecoveryState.needsRecovery == false)
        #expect(await transport.connectionState == .connected)

        await fulcrum.stop()
    }
}
