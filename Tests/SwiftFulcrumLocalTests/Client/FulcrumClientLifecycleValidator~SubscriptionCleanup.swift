// FulcrumClientLifecycleValidator~SubscriptionCleanup.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("stop() cancels pending subscription cleanup sends", .timeLimit(.minutes(1)))
    func stopCancelsPendingSubscriptionCleanupSends() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let unsubscribeMethodPath = SwiftFulcrum.RPC.Method.blockchain(.headers(.unsubscribe)).path

        let subscribeTask = Task {
            try await fulcrum.subscribe(
                SwiftFulcrum.API.blockchain.headers.subscribe,
                options: .init(timeout: .seconds(30))
            )
        }

        let request = try await decodeRequestObject(await transport.dequeueOutgoing())
        let identifier = try extractRequestIdentifier(from: request)
        let payload = try TransportTestActor.encodeResponsePayload(
            identifier: identifier,
            result: ["height": 900_200, "hex": String(repeating: "c", count: 160)]
        )
        await transport.enqueueIncoming(.data(payload))

        let subscription = try await subscribeTask.value
        let baselineUnsubscribeCount = try await countSentMethodOccurrences(
            unsubscribeMethodPath,
            transport: transport
        )

        await transport.configureOutgoingSendPaused(true)
        await subscription.cancel()

        let cleanupSendPaused = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(cleanupSendPaused)

        await fulcrum.stop()
        await transport.configureOutgoingSendPaused(false)
        try await Task.sleep(for: .milliseconds(150))

        let finalUnsubscribeCount = try await countSentMethodOccurrences(
            unsubscribeMethodPath,
            transport: transport
        )
        #expect(finalUnsubscribeCount == baselineUnsubscribeCount)
    }

    @Test("cancel() emits an unsubscribe request for active subscriptions", .timeLimit(.minutes(1)))
    func cancellingSubscriptionEmitsUnsubscribeRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))
        let unsubscribeMethodPath = SwiftFulcrum.RPC.Method.blockchain(.headers(.unsubscribe)).path

        let subscribeTask = Task {
            try await fulcrum.subscribe(
                method: subscribeMethod,
                initial: SwiftFulcrum.Response.Blockchain.Headers.Subscribe.self,
                notifications: SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self,
                options: .init(timeout: .seconds(30))
            )
        }

        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 930_000, "hex": String(repeating: "c", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))

        let subscription = try await subscribeTask.value
        let baselineUnsubscribeCount = try await countSentMethodOccurrences(
            unsubscribeMethodPath,
            transport: transport
        )

        await subscription.cancel()

        let didSendUnsubscribe = await waitUntil(timeout: .seconds(2)) {
            let unsubscribeCount = (try? await countSentMethodOccurrences(
                unsubscribeMethodPath,
                transport: transport
            )) ?? 0
            return unsubscribeCount == baselineUnsubscribeCount + 1
        }
        #expect(didSendUnsubscribe)
        #expect(await NetworkTestClient.detectStreamTermination(subscription.updates, within: .seconds(5)))

        await fulcrum.stop()
    }
}
