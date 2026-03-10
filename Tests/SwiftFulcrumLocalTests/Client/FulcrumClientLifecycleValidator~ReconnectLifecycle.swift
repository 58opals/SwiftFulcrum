// FulcrumClientLifecycleValidator~ReconnectLifecycle.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("reconnect renegotiates and resubscribes even without reconnect lifecycle events", .timeLimit(.minutes(1)))
    func reconnectRenegotiatesAndResubscribesWithoutLifecycleEvents() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        
        var subscribeTask: Task<
            (
                SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe,
                AsyncThrowingStream<SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification, Swift.Error>,
                @Sendable () async -> Void
            ),
            Swift.Error
        >? = Task {
            try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initialType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                notificationType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
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
        let initialSubscription: (
            SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe,
            AsyncThrowingStream<SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification, Swift.Error>,
            @Sendable () async -> Void
        )
        do {
            guard let task = subscribeTask else {
                Issue.record("Subscribe task should exist while awaiting the initial response")
                await fulcrum.stop()
                return
            }
            initialSubscription = try await task.value
        }
        subscribeTask = nil
        let (_, updates, cancel) = initialSubscription
        
        let subscribeMethodPath = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path
        let baselineSubscribeCount = try await countSentMethodOccurrences(
            subscribeMethodPath,
            transport: transport
        )
        
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
        
        let didResubscribe = await waitUntil(timeout: .seconds(2)) {
            let subscribeCount = (try? await countSentMethodOccurrences(
                subscribeMethodPath,
                transport: transport
            )) ?? 0
            return subscribeCount == baselineSubscribeCount + 1
        }
        
        #expect(didResubscribe)
        #expect((await fulcrum.listSubscriptions()).count == 1)
        
        await cancel()
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))
        await fulcrum.stop()
    }

    @Test("transport reconnect preserves active subscriptions and updates", .timeLimit(.minutes(1)))
    func transportReconnectPreservesActiveSubscriptionsAndUpdates() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        let subscribeTask = Task {
            try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initialType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                notificationType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
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

        let (initial, updates, cancel) = try await subscribeTask.value
        #expect(initial.height == 930_000)

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

        await cancel()
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))
        await fulcrum.stop()
    }

}
