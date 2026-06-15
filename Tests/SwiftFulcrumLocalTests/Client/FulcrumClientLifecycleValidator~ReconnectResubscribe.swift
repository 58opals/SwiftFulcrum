// FulcrumClientLifecycleValidator~ReconnectResubscribe.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
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
        let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
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
        let versionIdentifier = try extractRequestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try extractRequestIdentifier(from: featuresRequest)
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
        let reconnectResubscribeIdentifier = try extractRequestIdentifier(from: reconnectResubscribeRequest)
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
        #expect(await fulcrum.makeActiveSubscriptionCount() == 1)

        await initialSubscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))
        await fulcrum.stop()
    }
}
