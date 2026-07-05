// FulcrumClientLifecycleValidator~SubscriptionRegistry.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("subscription registry reflects subscribe/cancel lifecycle", .timeLimit(.minutes(1)))
    func reportSubscriptionLifecycle() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        #expect(await fulcrum.makeActiveSubscriptionStates().isEmpty)

        let subscribeTask = Task {
            try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initial: SwiftFulcrum.Response.Blockchain.Headers.Subscribe.self,
                notifications: SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self,
                options: .init(timeout: .seconds(30))
            )
        }

        let request = try await decodeRequestObject(await transport.dequeueOutgoing())
        let identifier = try #require(request["id"] as? String)
        let setupSubscriptions = await fulcrum.makeActiveSubscriptionStates()
        #expect(setupSubscriptions.count == 1)
        let setupSubscription = try #require(setupSubscriptions.first)
        #expect(setupSubscription.methodPath == SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path)
        #expect(setupSubscription.phase.contains("settingUp"))

        let payload = try TransportTestActor.encodeResponsePayload(
            identifier: identifier,
            result: ["height": 900_000, "hex": String(repeating: "a", count: 160)]
        )
        await transport.enqueueIncoming(.data(payload))

        let subscription = try await subscribeTask.value
        #expect(subscription.initial.height == 900_000)

        let activeSubscriptions = await fulcrum.makeActiveSubscriptionStates()
        #expect(activeSubscriptions.count == 1)
        let activeSubscription = try #require(activeSubscriptions.first)
        #expect(activeSubscription.methodPath == SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path)
        #expect(activeSubscription.phase.contains("active"))

        await subscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(subscription.updates, within: .seconds(5)))

        #expect(await fulcrum.makeActiveSubscriptionStates().isEmpty)

        await fulcrum.stop()
    }

    @Test("stop() clears active subscription registry", .timeLimit(.minutes(1)))
    func stopClearsActiveSubscriptionRegistry() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

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
            result: ["height": 900_100, "hex": String(repeating: "b", count: 160)]
        )
        await transport.enqueueIncoming(.data(payload))

        let subscription = try await subscribeTask.value
        #expect(await fulcrum.makeActiveSubscriptionCount() == 1)

        await fulcrum.stop()

        #expect(await fulcrum.makeActiveSubscriptionStates().isEmpty)
        #expect(await NetworkTestClient.detectStreamTermination(subscription.updates, within: .seconds(5)))
    }

    @Test("stale subscription cleanup does not remove newer same-key subscription", .timeLimit(.minutes(1)))
    func staleSubscriptionCleanupPreservesNewerSameKeySubscription() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client
        let subscriptionKey = FulcrumNetworkClient.SubscriptionKey(methodPath: .headers, identifier: nil)
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))

        let firstSubscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod, options: .init(timeout: .seconds(30)))
        }

        let firstRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let firstIdentifierString = try extractRequestIdentifier(from: firstRequest)
        let firstIdentifier = try #require(UUID(uuidString: firstIdentifierString))
        let firstPayload = try TransportTestActor.encodeResponsePayload(
            identifier: firstIdentifierString,
            result: ["height": 901_000, "hex": String(repeating: "d", count: 160)]
        )
        await transport.enqueueIncoming(.data(firstPayload))

        let firstSubscription = try await firstSubscribeTask.value
        _ = await networkClient.cleanUpSubscriptionSetup(
            for: subscriptionKey,
            requestIdentifier: firstIdentifier
        )
        #expect(await NetworkTestClient.detectStreamTermination(firstSubscription.updates, within: .seconds(5)))

        let secondSubscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod, options: .init(timeout: .seconds(30)))
        }

        let secondRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let secondIdentifierString = try extractRequestIdentifier(from: secondRequest)
        let secondPayload = try TransportTestActor.encodeResponsePayload(
            identifier: secondIdentifierString,
            result: ["height": 901_001, "hex": String(repeating: "e", count: 160)]
        )
        await transport.enqueueIncoming(.data(secondPayload))

        let secondSubscription = try await secondSubscribeTask.value
        let didRemoveNewerSubscription = await networkClient.cleanUpSubscriptionSetup(
            for: subscriptionKey,
            requestIdentifier: firstIdentifier
        )

        #expect(didRemoveNewerSubscription == false)
        let didRemoveNewerSubscriptionWithCancellation = await networkClient.cleanUpSubscriptionSetup(
            for: subscriptionKey,
            requestIdentifier: firstIdentifier,
            reason: .cancellation(SwiftFulcrum.Client.Error.client(.cancelled)),
            scope: .currentSetupThenRequest
        )

        #expect(didRemoveNewerSubscriptionWithCancellation == false)
        let activeSubscriptions = await fulcrum.makeActiveSubscriptionStates()
        #expect(activeSubscriptions.count == 1)
        let activeSubscription = try #require(activeSubscriptions.first)
        #expect(activeSubscription.phase.contains("active"))

        await secondSubscription.cancel()
        await fulcrum.stop()
    }
}
