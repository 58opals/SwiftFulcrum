// FulcrumClientLifecycleValidator~SubscriptionLifecycle.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("cancel() allows immediate same-key resubscribe", .timeLimit(.minutes(1)))
    func cancellingSubscriptionAllowsImmediateSameKeyResubscribe() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeEndpoint = SwiftFulcrum.API.blockchain.headers.subscribe
        let subscribeMethod = subscribeEndpoint.method

        let firstSubscribeTask = Task {
            try await fulcrum.subscribe(
                subscribeEndpoint,
                options: .init(timeout: .seconds(30))
            )
        }

        let firstSubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let firstSubscribeIdentifier = try extractRequestIdentifier(from: firstSubscribeRequest)
        let firstSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: firstSubscribeIdentifier,
            result: ["height": 925_000, "hex": String(repeating: "9", count: 160)]
        )
        await transport.enqueueIncoming(.data(firstSubscribePayload))

        let firstSubscription = try await firstSubscribeTask.value
        let firstUpdates = firstSubscription.updates
        let baselineSubscribeCount = try await countSentMethodOccurrences(subscribeMethod.path, transport: transport)

        await firstSubscription.cancel()

        let secondSubscribeTask = Task {
            try await fulcrum.subscribe(
                subscribeEndpoint,
                options: .init(timeout: .seconds(30))
            )
        }

        let didSendSecondSubscribe = await waitUntil(timeout: .seconds(2)) {
            let subscribeCount = (try? await countSentMethodOccurrences(
                subscribeMethod.path,
                transport: transport
            )) ?? 0
            return subscribeCount == baselineSubscribeCount + 1
        }
        #expect(didSendSecondSubscribe)

        var pendingSecondSubscribeRequest: [String: Any]?
        for _ in 0..<3 {
            let outgoingRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
            if outgoingRequest["method"] as? String == subscribeMethod.path {
                pendingSecondSubscribeRequest = outgoingRequest
                break
            }
        }
        let secondSubscribeRequest = try #require(pendingSecondSubscribeRequest)
        let secondSubscribeIdentifier = try extractRequestIdentifier(from: secondSubscribeRequest)
        let secondSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: secondSubscribeIdentifier,
            result: ["height": 925_001, "hex": String(repeating: "a", count: 160)]
        )
        await transport.enqueueIncoming(.data(secondSubscribePayload))

        let secondSubscription = try await secondSubscribeTask.value
        #expect(secondSubscription.initial.height == 925_001)
        #expect(await fulcrum.makeActiveSubscriptionCount() == 1)
        #expect(await NetworkTestClient.detectStreamTermination(firstUpdates, within: .seconds(5)))

        await secondSubscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(secondSubscription.updates, within: .seconds(5)))

        await fulcrum.stop()
    }

    @Test(
        "dropping decoded updates stream triggers unsubscribe cleanup",
        .timeLimit(.minutes(1)),
        .enabled(
            if: false,
            "Decoded stream drop cleanup is currently nondeterministic under Swift Testing task retention."
        )
    )
    func droppingDecodedUpdatesStreamTriggersUnsubscribeCleanup() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        var subscribeTask: Task<
            SwiftFulcrum.Client.Subscription<
                SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
                SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification
            >,
            Swift.Error
        >? = Task {
            try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initial: SwiftFulcrum.Response.Blockchain.Headers.Subscribe.self,
                notifications: SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self,
                options: .init(timeout: .seconds(30))
            )
        }

        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 920_000, "hex": String(repeating: "d", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))
        var updatesStream: AsyncThrowingStream<
            SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification,
            Swift.Error
        >?
        do {
            guard let task = subscribeTask else {
                Issue.record("Subscribe task should exist while awaiting the initial response")
                await fulcrum.stop()
                return
            }
            let subscription = try await task.value
            #expect(subscription.initial.height == 920_000)
            updatesStream = subscription.updates
        }
        subscribeTask = nil

        let notificationPayload = try TransportTestActor.encodeSubscriptionNotification(
            method: SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path,
            parameters: [[
                "height": 920_001,
                "hex": String(repeating: "e", count: 160)
            ]]
        )
        await transport.enqueueIncoming(.data(notificationPayload))

        guard updatesStream != nil else {
            Issue.record("Subscription should provide an updates stream")
            await fulcrum.stop()
            return
        }
        var transientUpdatesStream = updatesStream
        updatesStream = nil

        var consumeFirstUpdateTask: Task<
            SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification?,
            Swift.Error
        >? = Task { [transientUpdatesStream] in
            guard let stream = transientUpdatesStream else { return nil }
            var iterator = stream.makeAsyncIterator()
            return try await iterator.next()
        }
        transientUpdatesStream = nil
        guard let activeConsumeFirstUpdateTask = consumeFirstUpdateTask else {
            Issue.record("Failed to create update-consumer task")
            await fulcrum.stop()
            return
        }
        let firstUpdate = try await activeConsumeFirstUpdateTask.value
        consumeFirstUpdateTask = nil
        #expect(firstUpdate?.blocks.first?.height == 920_001)

        let registryDidClear = await waitUntil(timeout: .seconds(5)) {
            await fulcrum.makeActiveSubscriptionStates().isEmpty
        }
        #expect(registryDidClear)

        let unsubscribeMethodPath = SwiftFulcrum.RPC.Method.blockchain(.headers(.unsubscribe)).path
        let didSendUnsubscribe = await waitUntil(timeout: .seconds(5)) {
            let unsubscribeCount = (try? await countSentMethodOccurrences(
                unsubscribeMethodPath,
                transport: transport
            )) ?? 0
            return unsubscribeCount > 0
        }
        #expect(didSendUnsubscribe)

        await fulcrum.stop()
    }

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
