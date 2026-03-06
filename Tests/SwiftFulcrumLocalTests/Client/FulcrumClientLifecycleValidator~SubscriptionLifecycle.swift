import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("dropping decoded updates stream triggers unsubscribe cleanup", .timeLimit(.minutes(1)))
    func droppingDecodedUpdatesStreamTriggersUnsubscribeCleanup() async throws {
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
            result: ["height": 920_000, "hex": String(repeating: "d", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))
        var updatesStream: AsyncThrowingStream<
            SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification,
            Swift.Error
        >?
        do {
            guard let task = subscribeTask else {
                Issue.record("Subscribe task should exist while awaiting the initial response")
                await fulcrum.stop()
                return
            }
            let subscription = try await task.value
            #expect(subscription.0.height == 920_000)
            updatesStream = subscription.1
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
            SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification?,
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
            (await fulcrum.listSubscriptions()).isEmpty
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

    @Test("diagnostics and subscriptions reflect subscribe/cancel lifecycle", .timeLimit(.minutes(1)))
    func reportDiagnosticsAndSubscriptionLifecycle() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        let initialSnapshot = await fulcrum.makeDiagnosticsSnapshot()
        #expect(initialSnapshot.activeSubscriptionCount == 0)
        #expect((await fulcrum.listSubscriptions()).isEmpty)

        let subscribeTask = Task {
            try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initialType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                notificationType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
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

        let (initial, updates, cancel) = try await subscribeTask.value
        #expect(initial.height == 900_000)

        let activeSnapshot = await fulcrum.makeDiagnosticsSnapshot()
        let activeSubscriptions = await fulcrum.listSubscriptions()
        #expect(activeSnapshot.activeSubscriptionCount == 1)
        #expect(activeSubscriptions.count == 1)
        #expect(activeSubscriptions.first?.methodPath == SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path)

        await cancel()
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))

        let finalSnapshot = await fulcrum.makeDiagnosticsSnapshot()
        #expect(finalSnapshot.activeSubscriptionCount == 0)
        #expect((await fulcrum.listSubscriptions()).isEmpty)

        await fulcrum.stop()
    }

}
