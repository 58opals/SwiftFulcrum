// FulcrumClientLifecycleValidator~ReconnectRestoreSupersession.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("new reconnect preserves a subscription awaiting restore", .timeLimit(.minutes(1)))
    func preserveSubscriptionWhenReconnectSupersedesRestore() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client
        let method = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))
        let subscription = try await makeActiveHeadersSubscription(
            on: fulcrum,
            transport: transport
        )
        let updates = subscription.updates

        try await transport.reconnect(with: nil)
        await transport.configureConnectionState(.connected)
        let firstReconnectSuccessCount = await transport.reconnectSuccesses
        let firstRecoveryTask = try #require(
            await networkClient.beginAutomaticReconnectRecovery(
                reconnectSuccessCount: firstReconnectSuccessCount
            )
        )

        try await completeProtocolNegotiation(on: transport)
        let firstRestoreRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(firstRestoreRequest["method"] as? String == method.path)
        let didRegisterFirstRestoreRoute = await waitUntil(timeout: .seconds(2)) {
            await fulcrum.makeInflightUnaryCallCount() == 1
        }
        try #require(didRegisterFirstRestoreRoute)
        let firstRecoveryGeneration = try #require(
            await networkClient.reconnectRecoveryTaskGenerationIdentifier
        )

        await transport.configureConnectionState(.reconnecting)
        await networkClient.prepareForAutomaticReconnectRecoveryIfNeeded()

        #expect(firstRecoveryTask.isCancelled == false)
        #expect(
            await networkClient.reconnectRecoveryTaskGenerationIdentifier
                == firstRecoveryGeneration
        )
        #expect(await fulcrum.makeActiveSubscriptionCount() == 1)

        try await transport.reconnect(with: nil)
        await transport.configureConnectionState(.connected)
        let secondReconnectSuccessCount = await transport.reconnectSuccesses
        #expect(secondReconnectSuccessCount > firstReconnectSuccessCount)
        let secondRecoveryTask = try #require(
            await networkClient.beginAutomaticReconnectRecovery(
                reconnectSuccessCount: secondReconnectSuccessCount
            )
        )

        await #expect(throws: CancellationError.self) {
            try await firstRecoveryTask.value
        }

        let secondVersionRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(secondVersionRequest["method"] as? String == "server.version")
        let preservedSubscriptions = await fulcrum.makeActiveSubscriptionStates()
        #expect(preservedSubscriptions.count == 1)
        #expect(preservedSubscriptions.first?.phase.contains("active") == true)
        #expect(await fulcrum.makeInflightUnaryCallCount() == 1)

        let secondVersionIdentifier = try extractRequestIdentifier(
            from: secondVersionRequest
        )
        let secondVersionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: secondVersionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(secondVersionPayload))

        let secondFeaturesRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(secondFeaturesRequest["method"] as? String == "server.features")
        let secondFeaturesIdentifier = try extractRequestIdentifier(
            from: secondFeaturesRequest
        )
        let secondFeaturesPayload = try TransportTestActor.encodeResponsePayload(
            identifier: secondFeaturesIdentifier,
            result: [
                "genesis_hash": String(repeating: "0", count: 64),
                "hash_function": "sha256",
                "server_version": "SwiftFulcrum.Client 2.0",
                "protocol_max": "1.6.0",
                "protocol_min": "1.4.0"
            ]
        )
        await transport.enqueueIncoming(.data(secondFeaturesPayload))

        let secondRestoreRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(secondRestoreRequest["method"] as? String == method.path)
        let secondRestoreIdentifier = try extractRequestIdentifier(
            from: secondRestoreRequest
        )
        let secondRestorePayload = try TransportTestActor.encodeResponsePayload(
            identifier: secondRestoreIdentifier,
            result: [
                "height": 930_000,
                "hex": String(repeating: "b", count: 160)
            ]
        )
        await transport.enqueueIncoming(.data(secondRestorePayload))

        try await secondRecoveryTask.value
        #expect(await fulcrum.makeActiveSubscriptionCount() == 1)

        let notificationPayload = try TransportTestActor.encodeSubscriptionNotification(
            method: method.path,
            parameters: [[
                "height": 930_001,
                "hex": String(repeating: "c", count: 160)
            ]]
        )
        await transport.enqueueIncoming(.data(notificationPayload))

        let update = try await waitForFirstStreamElement(
            updates,
            within: .seconds(2)
        )
        #expect(update?.blocks.first?.height == 930_001)

        await subscription.cancel()
        await fulcrum.stop()
    }
}
