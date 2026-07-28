// FulcrumClientLifecycleValidator~ManualReconnectTakeover.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test(
        "manual reconnect preserves a restore canceled before transport advances",
        .timeLimit(.minutes(1))
    )
    func preserveRestoreWhenManualReconnectTakesOver() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client
        let method = SwiftFulcrum.RPC.Method.blockchain(
            .headers(.subscribe)
        )
        let subscription = try await makeActiveHeadersSubscription(
            on: fulcrum,
            transport: transport
        )

        try await transport.reconnect(with: nil)
        await transport.configureConnectionState(.connected)
        let automaticReconnectSuccessCount =
            await transport.reconnectSuccesses
        let automaticRecoveryTask = try #require(
            await networkClient.beginAutomaticReconnectRecovery(
                reconnectSuccessCount: automaticReconnectSuccessCount
            )
        )

        try await completeProtocolNegotiation(on: transport)
        let automaticRestoreRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(automaticRestoreRequest["method"] as? String == method.path)
        let didRegisterRestoreRoute = await waitUntil(timeout: .seconds(2)) {
            await fulcrum.makeInflightUnaryCallCount() == 1
        }
        try #require(didRegisterRestoreRoute)

        let manualReconnectTask = Task {
            try await fulcrum.reconnect()
        }

        await #expect(throws: CancellationError.self) {
            try await automaticRecoveryTask.value
        }
        #expect(await fulcrum.makeActiveSubscriptionCount() == 1)

        try await completeProtocolNegotiation(on: transport)
        let manualRestoreRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(manualRestoreRequest["method"] as? String == method.path)
        let manualRestoreIdentifier = try extractRequestIdentifier(
            from: manualRestoreRequest
        )
        let manualRestorePayload =
            try TransportTestActor.encodeResponsePayload(
                identifier: manualRestoreIdentifier,
                result: [
                    "height": 930_001,
                    "hex": String(repeating: "b", count: 160)
                ]
            )
        await transport.enqueueIncoming(.data(manualRestorePayload))

        try await manualReconnectTask.value
        #expect(await fulcrum.makeActiveSubscriptionCount() == 1)

        await subscription.cancel()
        await fulcrum.stop()
    }
}
