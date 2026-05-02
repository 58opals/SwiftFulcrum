// FulcrumClientLifecycleValidator~ReconnectLifecycle.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

private actor ReconnectCompletionState {
    private var completed = false

    func markCompleted() {
        completed = true
    }

    var isCompleted: Bool {
        completed
    }
}

private typealias HeadersSubscription = SwiftFulcrum.Client.Subscription<
    SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
    SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification
>

private typealias ScriptHashSubscription = SwiftFulcrum.Client.Subscription<
    SwiftFulcrum.Response.Blockchain.ScriptHash.Subscribe,
    SwiftFulcrum.Response.Blockchain.ScriptHash.SubscribeNotification
>

extension FulcrumClientLifecycleValidator {
    @Test("reconnect cleanup allows immediate same-key resubscribe", .timeLimit(.minutes(1)))
    func reconnectCleanupAllowsImmediateSameKeyResubscribe() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))

        let initialSubscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod, options: .init(timeout: .seconds(30)))
        }

        let initialSubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let initialSubscribeIdentifier = try requestIdentifier(from: initialSubscribeRequest)
        let initialSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: initialSubscribeIdentifier,
            result: ["height": 940_000, "hex": String(repeating: "f", count: 160)]
        )
        await transport.enqueueIncoming(.data(initialSubscribePayload))

        let initialSubscription = try await initialSubscribeTask.value
        let updates = initialSubscription.updates
        let baselineSubscribeCount = try await countSentMethodOccurrences(subscribeMethod.path, transport: transport)

        await transport.enqueueLifecycleEvent(.disconnected(code: .goingAway, reason: "same-key reconnect test"))
        await transport.enqueueLifecycleEvent(.connected(isReconnect: true))

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try requestIdentifier(from: featuresRequest)
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

        let didResubscribe = await waitUntil(timeout: .seconds(2)) {
            let subscribeCount = (try? await countSentMethodOccurrences(
                subscribeMethod.path,
                transport: transport
            )) ?? 0
            return subscribeCount == baselineSubscribeCount + 1
        }
        #expect(didResubscribe)

        let reconnectResubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(reconnectResubscribeRequest["method"] as? String == subscribeMethod.path)
        let reconnectResubscribeIdentifier = try requestIdentifier(from: reconnectResubscribeRequest)
        let reconnectResubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: reconnectResubscribeIdentifier,
            result: ["height": 940_000, "hex": String(repeating: "f", count: 160)]
        )
        await transport.enqueueIncoming(.data(reconnectResubscribePayload))

        await initialSubscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))

        let didClearInitialSubscription = await waitUntil(timeout: .seconds(5)) {
            (await fulcrum.listSubscriptions()).isEmpty
        }
        #expect(didClearInitialSubscription)

        let postReconnectSubscribeCount = try await countSentMethodOccurrences(subscribeMethod.path, transport: transport)
        let replacementSubscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod, options: .init(timeout: .seconds(30)))
        }

        let didSendReplacementSubscribe = await waitUntil(timeout: .seconds(2)) {
            let subscribeCount = (try? await countSentMethodOccurrences(
                subscribeMethod.path,
                transport: transport
            )) ?? 0
            return subscribeCount == postReconnectSubscribeCount + 1
        }
        try #require(didSendReplacementSubscribe)

        var pendingReplacementSubscribeRequest: [String: Any]?
        for _ in 0..<3 {
            let outgoingRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
            if outgoingRequest["method"] as? String == subscribeMethod.path {
                pendingReplacementSubscribeRequest = outgoingRequest
                break
            }
        }
        let replacementSubscribeRequest = try #require(pendingReplacementSubscribeRequest)
        let replacementSubscribeIdentifier = try requestIdentifier(from: replacementSubscribeRequest)
        let replacementSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: replacementSubscribeIdentifier,
            result: ["height": 940_001, "hex": String(repeating: "1", count: 160)]
        )
        await transport.enqueueIncoming(.data(replacementSubscribePayload))

        let replacementSubscription = try await replacementSubscribeTask.value
        #expect(replacementSubscription.initial.height == 940_001)
        #expect((await fulcrum.listSubscriptions()).count == 1)

        await replacementSubscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(replacementSubscription.updates, within: .seconds(5)))

        await fulcrum.stop()
    }

    @Test("reconnect renegotiates and resubscribes even without reconnect lifecycle events", .timeLimit(.minutes(1)))
    func reconnectRenegotiatesAndResubscribesWithoutLifecycleEvents() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        var subscribeTask: Task<HeadersSubscription, Swift.Error>? = Task {
            try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                options: .init(timeout: .seconds(30))
            )
        }

        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try requestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 910_000, "hex": String(repeating: "c", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))
        let initialSubscription: HeadersSubscription
        do {
            guard let task = subscribeTask else {
                Issue.record("Subscribe task should exist while awaiting the initial response")
                await fulcrum.stop()
                return
            }
            initialSubscription = try await task.value
        }
        subscribeTask = nil
        let updates = initialSubscription.updates

        let subscribeMethodPath = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path
        let baselineSubscribeCount = try await countSentMethodOccurrences(
            subscribeMethodPath,
            transport: transport
        )

        let reconnectCompletion = ReconnectCompletionState()
        let reconnectTask = Task {
            do {
                try await fulcrum.reconnect()
                await reconnectCompletion.markCompleted()
            } catch {
                await reconnectCompletion.markCompleted()
                throw error
            }
        }

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try requestIdentifier(from: featuresRequest)
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

        let didResubscribe = await waitUntil(timeout: .seconds(2)) {
            let subscribeCount = (try? await countSentMethodOccurrences(
                subscribeMethodPath,
                transport: transport
            )) ?? 0
            return subscribeCount == baselineSubscribeCount + 1
        }

        #expect(didResubscribe)
        let reconnectResubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let reconnectResubscribeIdentifier = try requestIdentifier(from: reconnectResubscribeRequest)
        #expect(reconnectResubscribeRequest["method"] as? String == subscribeMethodPath)

        let didFinishBeforeAck = await waitUntil(timeout: .milliseconds(150)) {
            await reconnectCompletion.isCompleted
        }
        #expect(didFinishBeforeAck == false)

        let reconnectResubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: reconnectResubscribeIdentifier,
            result: ["height": 910_000, "hex": String(repeating: "c", count: 160)]
        )
        await transport.enqueueIncoming(.data(reconnectResubscribePayload))

        try await reconnectTask.value
        #expect((await fulcrum.listSubscriptions()).count == 1)

        await initialSubscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))
        await fulcrum.stop()
    }

    @Test("cancel during reconnect restore completes without restore response", .timeLimit(.minutes(1)))
    func cancelDuringReconnectRestoreCompletesWithoutRestoreResponse() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))

        let subscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod, options: .init(timeout: .seconds(30)))
        }

        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try requestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 920_000, "hex": String(repeating: "d", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))
        let subscription = try await subscribeTask.value
        let updates = subscription.updates

        let reconnectCompletion = ReconnectCompletionState()
        let reconnectTask = Task {
            do {
                try await fulcrum.reconnect()
                await reconnectCompletion.markCompleted()
            } catch {
                await reconnectCompletion.markCompleted()
                throw error
            }
        }

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try requestIdentifier(from: featuresRequest)
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

        let restoreRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(restoreRequest["method"] as? String == subscribeMethod.path)

        let didFinishBeforeCancel = await waitUntil(timeout: .milliseconds(150)) {
            await reconnectCompletion.isCompleted
        }
        #expect(didFinishBeforeCancel == false)

        await subscription.cancel()

        let didReconnectFinish = await waitUntil(timeout: .seconds(2)) {
            await reconnectCompletion.isCompleted
        }
        #expect(didReconnectFinish)

        if didReconnectFinish {
            try await reconnectTask.value
        } else {
            reconnectTask.cancel()
        }

        let didClearSubscriptions = await waitUntil(timeout: .seconds(2)) {
            (await fulcrum.listSubscriptions()).isEmpty
        }
        #expect(didClearSubscriptions)
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))

        await fulcrum.stop()
    }

    @Test("cancel during paused reconnect restore send does not emit a late request", .timeLimit(.minutes(1)))
    func cancelDuringPausedReconnectRestoreSendDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))

        let subscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod, options: .init(timeout: .seconds(30)))
        }

        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try requestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 925_000, "hex": String(repeating: "e", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))
        let subscription = try await subscribeTask.value
        let updates = subscription.updates

        let reconnectCompletion = ReconnectCompletionState()
        let reconnectTask = Task {
            do {
                try await fulcrum.reconnect()
                await reconnectCompletion.markCompleted()
            } catch {
                await reconnectCompletion.markCompleted()
                throw error
            }
        }

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let baselineOutgoingCount = await transport.sentMessages.count
        await transport.configureOutgoingSendPaused(true)

        let featuresIdentifier = try requestIdentifier(from: featuresRequest)
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

        let didPauseRestoreSend = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(didPauseRestoreSend)

        let didFinishBeforeCancel = await waitUntil(timeout: .milliseconds(150)) {
            await reconnectCompletion.isCompleted
        }
        #expect(didFinishBeforeCancel == false)
        #expect(await transport.sentMessages.count == baselineOutgoingCount)

        await subscription.cancel()

        let didClearSubscriptions = await waitUntil(timeout: .seconds(2)) {
            (await fulcrum.listSubscriptions()).isEmpty
        }
        #expect(didClearSubscriptions)
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))

        await transport.configureOutgoingSendPaused(false)

        let didReconnectFinish = await waitUntil(timeout: .seconds(2)) {
            await reconnectCompletion.isCompleted
        }
        #expect(didReconnectFinish)

        if didReconnectFinish {
            try await reconnectTask.value
        } else {
            reconnectTask.cancel()
        }

        try? await Task.sleep(for: .milliseconds(150))
        #expect(await transport.sentMessages.count == baselineOutgoingCount)

        await fulcrum.stop()
    }

    @Test("transport reconnect preserves active subscriptions and updates", .timeLimit(.minutes(1)))
    func transportReconnectPreservesActiveSubscriptionsAndUpdates() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        let subscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                options: .init(timeout: .seconds(30))
            )
        }

        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try requestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 930_000, "hex": String(repeating: "f", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))

        let subscription = try await subscribeTask.value
        #expect(subscription.initial.height == 930_000)
        let updates = subscription.updates

        let subscribeMethodPath = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path
        let baselineSubscribeCount = try await countSentMethodOccurrences(
            subscribeMethodPath,
            transport: transport
        )

        await transport.enqueueLifecycleEvent(.disconnected(code: .goingAway, reason: "transport reconnect test"))
        await transport.enqueueLifecycleEvent(.connected(isReconnect: true))

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try requestIdentifier(from: featuresRequest)
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

        let didResubscribe = await waitUntil(timeout: .seconds(2)) {
            let subscribeCount = (try? await countSentMethodOccurrences(
                subscribeMethodPath,
                transport: transport
            )) ?? 0
            return subscribeCount == baselineSubscribeCount + 1
        }

        #expect(didResubscribe)
        let reconnectResubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let reconnectResubscribeIdentifier = try requestIdentifier(from: reconnectResubscribeRequest)
        #expect(reconnectResubscribeRequest["method"] as? String == subscribeMethodPath)
        let reconnectResubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: reconnectResubscribeIdentifier,
            result: ["height": 930_000, "hex": String(repeating: "f", count: 160)]
        )
        await transport.enqueueIncoming(.data(reconnectResubscribePayload))
        #expect((await fulcrum.listSubscriptions()).count == 1)

        let notificationPayload = try TransportTestActor.encodeSubscriptionNotification(
            method: subscribeMethodPath,
            parameters: [[
                "height": 930_001,
                "hex": String(repeating: "1", count: 160)
            ]]
        )
        await transport.enqueueIncoming(.data(notificationPayload))

        var iterator = updates.makeAsyncIterator()
        let update = try await iterator.next()
        #expect(update?.blocks.first?.height == 930_001)

        await subscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))
        await fulcrum.stop()
    }

    @Test("request remains usable after reconnect negotiation completes", .timeLimit(.minutes(1)))
    func requestRemainsUsableAfterReconnectNegotiationCompletes() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))
        let requestMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))

        let subscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod, options: .init(timeout: .seconds(30)))
        }

        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try requestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 935_000, "hex": String(repeating: "7", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))
        let subscription = try await subscribeTask.value
        let updates = subscription.updates

        let reconnectTask = Task {
            try await fulcrum.reconnect()
        }

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try requestIdentifier(from: featuresRequest)
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

        let restoreRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(restoreRequest["method"] as? String == subscribeMethod.path)
        let restoreIdentifier = try requestIdentifier(from: restoreRequest)

        let requestTask = Task {
            try await fulcrum.request(
                method: requestMethod,
                responseType: SwiftFulcrum.Response.Blockchain.Headers.GetTip.self,
                options: .init(timeout: .seconds(30))
            )
        }

        let didSendRequestEarly = await waitUntil(timeout: .milliseconds(150)) {
            let requestCount = (try? await countSentMethodOccurrences(
                requestMethod.path,
                transport: transport
            )) ?? 0
            return requestCount > 0
        }
        #expect(didSendRequestEarly == false)

        let restorePayload = try TransportTestActor.encodeResponsePayload(
            identifier: restoreIdentifier,
            result: ["height": 935_000, "hex": String(repeating: "7", count: 160)]
        )
        await transport.enqueueIncoming(.data(restorePayload))

        try await reconnectTask.value

        let request = try await nextRequestObject(
            matching: requestMethod.path,
            transport: transport
        )
        let requestIdentifier = try requestIdentifier(from: request)
        let requestPayload = try TransportTestActor.encodeResponsePayload(
            identifier: requestIdentifier,
            result: ["height": 935_001, "hex": String(repeating: "8", count: 160)]
        )
        await transport.enqueueIncoming(.data(requestPayload))

        let result = try await requestTask.value
        #expect(result.height == 935_001)
        #expect(result.hex == String(repeating: "8", count: 160))

        await subscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))
        await fulcrum.stop()
    }

    @Test("request waits for automatic reconnect recovery", .timeLimit(.minutes(1)))
    func requestWaitsForAutomaticReconnectRecovery() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let requestMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))

        try await transport.reconnect(with: nil)

        let requestTask = Task {
            try await fulcrum.request(
                method: requestMethod,
                responseType: SwiftFulcrum.Response.Blockchain.Headers.GetTip.self,
                options: .init(timeout: .seconds(30))
            )
        }

        let didSendRequestEarly = await waitUntil(timeout: .milliseconds(150)) {
            let requestCount = (try? await countSentMethodOccurrences(
                requestMethod.path,
                transport: transport
            )) ?? 0
            return requestCount > 0
        }
        #expect(didSendRequestEarly == false)

        guard !didSendRequestEarly else {
            requestTask.cancel()
            await fulcrum.stop()
            return
        }

        await transport.enqueueLifecycleEvent(.connected(isReconnect: true))

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try requestIdentifier(from: featuresRequest)
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

        let request = try await nextRequestObject(
            matching: requestMethod.path,
            transport: transport
        )
        let requestIdentifier = try requestIdentifier(from: request)
        let requestPayload = try TransportTestActor.encodeResponsePayload(
            identifier: requestIdentifier,
            result: ["height": 936_001, "hex": String(repeating: "9", count: 160)]
        )
        await transport.enqueueIncoming(.data(requestPayload))

        let result = try await requestTask.value
        #expect(result.height == 936_001)
        #expect(result.hex == String(repeating: "9", count: 160))

        await fulcrum.stop()
    }

    @Test("request waits when automatic reconnect is connected before recovery", .timeLimit(.minutes(1)))
    func requestWaitsWhenAutomaticReconnectIsConnectedBeforeRecovery() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let requestMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))

        await transport.configureConnectionState(.reconnecting)
        try? await Task.sleep(for: .milliseconds(250))
        await transport.configureConnectionState(.connected)

        let requestTask = Task {
            try await fulcrum.request(
                method: requestMethod,
                responseType: SwiftFulcrum.Response.Blockchain.Headers.GetTip.self,
                options: .init(timeout: .seconds(30))
            )
        }

        let didSendRequestEarly = await waitUntil(timeout: .milliseconds(150)) {
            let requestCount = (try? await countSentMethodOccurrences(
                requestMethod.path,
                transport: transport
            )) ?? 0
            return requestCount > 0
        }
        #expect(didSendRequestEarly == false)

        guard !didSendRequestEarly else {
            requestTask.cancel()
            await fulcrum.stop()
            return
        }

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try requestIdentifier(from: featuresRequest)
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

        let request = try await nextRequestObject(
            matching: requestMethod.path,
            transport: transport
        )
        let requestIdentifier = try requestIdentifier(from: request)
        let requestPayload = try TransportTestActor.encodeResponsePayload(
            identifier: requestIdentifier,
            result: ["height": 936_002, "hex": String(repeating: "a", count: 160)]
        )
        await transport.enqueueIncoming(.data(requestPayload))

        let result = try await requestTask.value
        #expect(result.height == 936_002)
        #expect(result.hex == String(repeating: "a", count: 160))

        await fulcrum.stop()
    }

    @Test("automatic reconnect negotiation failure disconnects transport", .timeLimit(.minutes(1)))
    func automaticReconnectNegotiationFailureDisconnectsTransport() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        await transport.configureConnectionState(.reconnecting)
        await transport.enqueueLifecycleEvent(.connected(isReconnect: true))

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.3.0"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let didDisconnect = await waitUntil(timeout: .milliseconds(250)) {
            await transport.connectionState == .disconnected
        }
        #expect(didDisconnect)

        await fulcrum.stop()
    }

    @Test("request(timeout:) uses one end-to-end budget while waiting for reconnect readiness", .timeLimit(.minutes(1)))
    func requestTimeoutUsesSingleBudgetWhileWaitingForReconnectReadiness() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let requestMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))
        let timeout: Duration = .milliseconds(200)

        let reconnectTask = Task {
            try await fulcrum.reconnect()
        }

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try requestIdentifier(from: featuresRequest)
        let baselineOutgoingCount = await transport.sentMessages.count

        let requestTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.request(
                    method: requestMethod,
                    responseType: SwiftFulcrum.Response.Blockchain.Headers.GetTip.self,
                    options: .init(timeout: timeout)
                )
                Issue.record("request() should time out after spending the single reconnect-readiness budget.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }

        try? await Task.sleep(for: .milliseconds(120))
        await transport.configureOutgoingSendDelay(.milliseconds(100))

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

        try await reconnectTask.value

        let error = await requestTask.value
        #expect(error == .client(.timeout(timeout)))

        try? await Task.sleep(for: .milliseconds(250))
        #expect(await transport.sentMessages.count == baselineOutgoingCount)

        await fulcrum.stop()
    }

    private func nextRequestObject(
        matching methodPath: String,
        transport: TransportTestActor
    ) async throws -> [String: Any] {
        while true {
            let request = try await decodeRequestObject(await transport.dequeueOutgoing())
            let queuedMethodPath = try #require(request["method"] as? String)

            switch queuedMethodPath {
            case methodPath:
                return request
            case SwiftFulcrum.RPC.Method.server(.ping).path:
                let pingIdentifier = try requestIdentifier(from: request)
                let pingPayload = try TransportTestActor.encodeResponsePayload(
                    identifier: pingIdentifier,
                    result: NSNull()
                )
                await transport.enqueueIncoming(.data(pingPayload))
            default:
                Issue.record("Unexpected request during reconnect recovery: \(queuedMethodPath)")
            }
        }
    }

    @Test("reconnect restore error removes failed subscription and preserves others", .timeLimit(.minutes(1)))
    func reconnectRestoreErrorRemovesFailedSubscriptionAndPreservesOthers() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let headersMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))
        let scripthashIdentifier = String(repeating: "b", count: 64)
        let scripthashMethod = SwiftFulcrum.RPC.Method.blockchain(.scripthash(.subscribe(scripthash: scripthashIdentifier)))

        let headersSubscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: headersMethod, options: .init(timeout: .seconds(30)))
        }

        let headersSubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let headersSubscribeIdentifier = try requestIdentifier(from: headersSubscribeRequest)
        let headersSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: headersSubscribeIdentifier,
            result: ["height": 950_000, "hex": String(repeating: "1", count: 160)]
        )
        await transport.enqueueIncoming(.data(headersSubscribePayload))
        let headersSubscription = try await headersSubscribeTask.value
        let headersUpdates = headersSubscription.updates

        let scripthashSubscribeTask = Task<ScriptHashSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: scripthashMethod, options: .init(timeout: .seconds(30)))
        }

        let scripthashSubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let scripthashSubscribeIdentifier = try requestIdentifier(from: scripthashSubscribeRequest)
        let scripthashSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: scripthashSubscribeIdentifier,
            result: "confirmed-status"
        )
        await transport.enqueueIncoming(.data(scripthashSubscribePayload))
        let scripthashSubscription = try await scripthashSubscribeTask.value
        let scripthashUpdates = scripthashSubscription.updates

        #expect((await fulcrum.listSubscriptions()).count == 2)

        let reconnectTask = Task {
            try await fulcrum.reconnect()
        }

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try requestIdentifier(from: featuresRequest)
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

        for _ in 0..<2 {
            let restoreRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
            let restoreIdentifier = try requestIdentifier(from: restoreRequest)
            let restoreMethodPath = try #require(restoreRequest["method"] as? String)

            switch restoreMethodPath {
            case headersMethod.path:
                let restorePayload = try TransportTestActor.encodeResponsePayload(
                    identifier: restoreIdentifier,
                    result: ["height": 950_000, "hex": String(repeating: "1", count: 160)]
                )
                await transport.enqueueIncoming(.data(restorePayload))
            case scripthashMethod.path:
                let restorePayload = try TransportTestActor.encodeErrorPayload(
                    identifier: restoreIdentifier,
                    code: -32001,
                    message: "restore rejected"
                )
                await transport.enqueueIncoming(.data(restorePayload))
            default:
                Issue.record("Unexpected restore request: \(restoreMethodPath)")
            }
        }

        try await reconnectTask.value

        let activeSubscriptions = await fulcrum.listSubscriptions()
        #expect(activeSubscriptions.count == 1)
        #expect(activeSubscriptions.first?.methodPath == headersMethod.path)

        let failedRestoreError = await waitForStreamTerminalError(scripthashUpdates, within: .seconds(2))
        guard case .rpc(let serverError) = failedRestoreError as? SwiftFulcrum.Client.Error else {
            Issue.record("Expected failed restore to terminate with RPC error, got \(String(describing: failedRestoreError))")
            await headersSubscription.cancel()
            await fulcrum.stop()
            return
        }
        #expect(serverError.code == -32001)
        #expect(serverError.message == "restore rejected")

        let notificationPayload = try TransportTestActor.encodeSubscriptionNotification(
            method: headersMethod.path,
            parameters: [[
                "height": 950_001,
                "hex": String(repeating: "2", count: 160)
            ]]
        )
        await transport.enqueueIncoming(.data(notificationPayload))

        var headersIterator = headersUpdates.makeAsyncIterator()
        let update = try await headersIterator.next()
        #expect(update?.blocks.first?.height == 950_001)

        await headersSubscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(headersUpdates, within: .seconds(5)))
        await fulcrum.stop()
    }

    @Test("reconnect restore send failure removes failed subscription", .timeLimit(.minutes(1)))
    func reconnectRestoreSendFailureRemovesFailedSubscription() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))

        let subscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod, options: .init(timeout: .seconds(30)))
        }

        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try requestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 960_000, "hex": String(repeating: "3", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))
        let subscription = try await subscribeTask.value
        let updates = subscription.updates

        let sendFailure = SwiftFulcrum.Client.Error.transport(.reconnectFailed)
        await transport.configureOutgoingSendFailure(sendFailure, forMethodPath: subscribeMethod.path)

        let reconnectTask = Task {
            try await fulcrum.reconnect()
        }

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try requestIdentifier(from: featuresRequest)
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

        try await reconnectTask.value

        #expect((await fulcrum.listSubscriptions()).isEmpty)

        let terminalError = await waitForStreamTerminalError(updates, within: .seconds(2))
        guard case .transport(.reconnectFailed) = terminalError as? SwiftFulcrum.Client.Error else {
            Issue.record("Expected restore send failure to terminate with reconnectFailed, got \(String(describing: terminalError))")
            await fulcrum.stop()
            return
        }

        await fulcrum.stop()
    }

}
