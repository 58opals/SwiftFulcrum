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
        let payload = try TransportTestActor.encodeResponsePayload(
            identifier: identifier,
            result: ["height": 900_000, "hex": String(repeating: "a", count: 160)]
        )
        await transport.enqueueIncoming(.data(payload))

        let subscription = try await subscribeTask.value
        #expect(subscription.initial.height == 900_000)

        let activeSubscriptions = await fulcrum.makeActiveSubscriptionStates()
        #expect(activeSubscriptions.count == 1)
        #expect(activeSubscriptions.first?.methodPath == SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path)

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
}
