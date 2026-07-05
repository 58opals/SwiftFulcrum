// FulcrumClientLifecycleValidator~SubscriptionLifecycle.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("subscription buffers default to bounded capacity 256")
    func subscriptionBuffersDefaultToBoundedCapacity256() {
        let options = SwiftFulcrum.Client.Call.Options()
        #expect(options.subscriptionBufferPolicy == .bounded(capacity: 256))

        let internalOptions = FulcrumNetworkClient.Call.Options()
        #expect(internalOptions.subscriptionBufferPolicy == .bounded(capacity: 256))
    }

    @Test("invalid subscription buffer capacity fails before registry insert", .timeLimit(.minutes(1)))
    func invalidSubscriptionBufferCapacityFailsBeforeRegistryInsert() async throws {
        let (fulcrum, _) = try await makeStartedFulcrum()

        do {
            let _: HeadersSubscription = try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                options: .init(timeout: .seconds(30), subscriptionBufferPolicy: .bounded(capacity: 0))
            )
            Issue.record("Expected invalid subscription buffer capacity to fail")
        } catch let error as SwiftFulcrum.Client.Error {
            guard case .client(.invalidSubscriptionBufferCapacity(let capacity)) = error else {
                Issue.record("Expected invalid subscription buffer capacity, got \(error)")
                await fulcrum.stop()
                return
            }
            #expect(capacity == 0)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }

        #expect(await fulcrum.makeActiveSubscriptionStates().isEmpty)
        await fulcrum.stop()
    }

    @Test("duplicate same-key subscribe failure preserves active subscription", .timeLimit(.minutes(1)))
    func duplicateSameKeySubscribeFailurePreservesActiveSubscription() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))
        let unsubscribeMethodPath = SwiftFulcrum.RPC.Method.blockchain(.headers(.unsubscribe)).path

        let firstSubscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(
                method: subscribeMethod,
                options: .init(timeout: .seconds(30))
            )
        }

        let firstSubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let firstSubscribeIdentifier = try extractRequestIdentifier(from: firstSubscribeRequest)
        let firstSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: firstSubscribeIdentifier,
            result: ["height": 934_100, "hex": String(repeating: "a", count: 160)]
        )
        await transport.enqueueIncoming(.data(firstSubscribePayload))

        let firstSubscription = try await firstSubscribeTask.value

        await #expect(throws: SwiftFulcrum.Client.Error.client(.duplicateRegistration)) {
            let _: HeadersSubscription = try await fulcrum.subscribe(
                method: subscribeMethod,
                options: .init(timeout: .seconds(30))
            )
        }

        #expect(await fulcrum.makeActiveSubscriptionCount() == 1)

        let baselineUnsubscribeCount = try await countSentMethodOccurrences(
            unsubscribeMethodPath,
            transport: transport
        )
        await firstSubscription.cancel()

        let didClearRegistry = await waitUntil(timeout: .seconds(5)) {
            await fulcrum.makeActiveSubscriptionStates().isEmpty
        }
        #expect(didClearRegistry)

        let didSendUnsubscribe = await waitUntil(timeout: .seconds(5)) {
            let unsubscribeCount = (try? await countSentMethodOccurrences(
                unsubscribeMethodPath,
                transport: transport
            )) ?? 0
            return unsubscribeCount == baselineUnsubscribeCount + 1
        }
        #expect(didSendUnsubscribe)

        await fulcrum.stop()
    }

    @Test("updates.cancel() emits unsubscribe and clears registry", .timeLimit(.minutes(1)))
    func updatesCancelEmitsUnsubscribeAndClearsRegistry() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))
        let unsubscribeMethodPath = SwiftFulcrum.RPC.Method.blockchain(.headers(.unsubscribe)).path

        let subscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(
                method: subscribeMethod,
                options: .init(timeout: .seconds(30))
            )
        }

        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 934_000, "hex": String(repeating: "f", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))

        let subscription = try await subscribeTask.value
        let updates = subscription.updates
        let baselineUnsubscribeCount = try await countSentMethodOccurrences(
            unsubscribeMethodPath,
            transport: transport
        )

        await updates.cancel()

        let registryDidClear = await waitUntil(timeout: .seconds(5)) {
            await fulcrum.makeActiveSubscriptionStates().isEmpty
        }
        #expect(registryDidClear)

        let didSendUnsubscribe = await waitUntil(timeout: .seconds(5)) {
            let unsubscribeCount = (try? await countSentMethodOccurrences(
                unsubscribeMethodPath,
                transport: transport
            )) ?? 0
            return unsubscribeCount == baselineUnsubscribeCount + 1
        }
        #expect(didSendUnsubscribe)
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))

        await fulcrum.stop()
    }

    @Test("subscription update overflow terminates only affected stream", .timeLimit(.minutes(1)))
    func subscriptionUpdateOverflowTerminatesOnlyAffectedStream() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let headersMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))
        let headersUnsubscribeMethodPath = SwiftFulcrum.RPC.Method.blockchain(.headers(.unsubscribe)).path
        let scriptHash = String(repeating: "0", count: 64)
        let scriptHashMethod = SwiftFulcrum.RPC.Method.blockchain(.scripthash(.subscribe(scripthash: scriptHash)))

        let headersSubscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(
                method: headersMethod,
                options: .init(timeout: .seconds(30), subscriptionBufferPolicy: .bounded(capacity: 1))
            )
        }

        let headersSubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let headersSubscribeIdentifier = try extractRequestIdentifier(from: headersSubscribeRequest)
        let headersSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: headersSubscribeIdentifier,
            result: ["height": 940_000, "hex": String(repeating: "1", count: 160)]
        )
        await transport.enqueueIncoming(.data(headersSubscribePayload))
        let headersSubscription = try await headersSubscribeTask.value
        let headersUpdates = headersSubscription.updates

        let scriptHashSubscribeTask = Task<ScriptHashSubscription, Swift.Error> {
            try await fulcrum.subscribe(
                method: scriptHashMethod,
                options: .init(timeout: .seconds(30), subscriptionBufferPolicy: .bounded(capacity: 1))
            )
        }

        let scriptHashSubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let scriptHashSubscribeIdentifier = try extractRequestIdentifier(from: scriptHashSubscribeRequest)
        let scriptHashSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: scriptHashSubscribeIdentifier,
            result: "initial-status"
        )
        await transport.enqueueIncoming(.data(scriptHashSubscribePayload))
        let scriptHashSubscription = try await scriptHashSubscribeTask.value
        let scriptHashUpdates = scriptHashSubscription.updates

        let baselineHeadersUnsubscribeCount = try await countSentMethodOccurrences(
            headersUnsubscribeMethodPath,
            transport: transport
        )

        let firstHeadersNotificationPayload = try TransportTestActor.encodeSubscriptionNotification(
            method: headersMethod.path,
            parameters: [[
                "height": 940_001,
                "hex": String(repeating: "2", count: 160)
            ]]
        )
        await transport.enqueueIncoming(.data(firstHeadersNotificationPayload))

        let secondHeadersNotificationPayload = try TransportTestActor.encodeSubscriptionNotification(
            method: headersMethod.path,
            parameters: [[
                "height": 940_002,
                "hex": String(repeating: "3", count: 160)
            ]]
        )
        await transport.enqueueIncoming(.data(secondHeadersNotificationPayload))

        let registryContainsOnlyScriptHash = await waitUntil(timeout: .seconds(5)) {
            let activeSubscriptions = await fulcrum.makeActiveSubscriptionStates()
            return activeSubscriptions.count == 1
                && activeSubscriptions.first?.methodPath == scriptHashMethod.path
                && activeSubscriptions.first?.identifier == scriptHash
        }
        #expect(registryContainsOnlyScriptHash)

        let didSendHeadersUnsubscribe = await waitUntil(timeout: .seconds(5)) {
            let unsubscribeCount = (try? await countSentMethodOccurrences(
                headersUnsubscribeMethodPath,
                transport: transport
            )) ?? 0
            return unsubscribeCount == baselineHeadersUnsubscribeCount + 1
        }
        #expect(didSendHeadersUnsubscribe)

        let overflowError = await waitForStreamTerminalError(headersUpdates, within: .seconds(5))
        guard case .client(.subscriptionUpdateBufferOverflow(let capacity)) = overflowError as? SwiftFulcrum.Client.Error else {
            Issue.record("Expected subscription update buffer overflow, got \(String(describing: overflowError))")
            await scriptHashSubscription.cancel()
            await fulcrum.stop()
            return
        }
        #expect(capacity == 1)

        let scriptHashNotificationPayload = try TransportTestActor.encodeSubscriptionNotification(
            method: scriptHashMethod.path,
            parameters: [scriptHash, "next-status"]
        )
        await transport.enqueueIncoming(.data(scriptHashNotificationPayload))

        let scriptHashUpdate = try await waitForFirstStreamElement(scriptHashUpdates, within: .seconds(5))
        #expect(scriptHashUpdate?.subscriptionIdentifier == scriptHash)
        #expect(scriptHashUpdate?.status == "next-status")

        await scriptHashSubscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(scriptHashUpdates, within: .seconds(5)))

        await fulcrum.stop()
    }

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

    @Test("dropping decoded updates stream triggers unsubscribe cleanup", .timeLimit(.minutes(1)))
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
        var updatesStream: SwiftFulcrum.Client.Subscription<
            SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
            SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification
        >.Updates?
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
}
