// FulcrumClientLifecycleValidator~ReconnectLifecycle.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("reconnect cleanup allows immediate same-key resubscribe", .timeLimit(.minutes(1)))
    func reconnectCleanupAllowsImmediateSameKeyResubscribe() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))

        let initialSubscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod, options: .init(timeout: .seconds(30)))
        }

        let initialSubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let initialSubscribeIdentifier = try extractRequestIdentifier(from: initialSubscribeRequest)
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
                subscribeMethod.path,
                transport: transport
            )) ?? 0
            return subscribeCount == baselineSubscribeCount + 1
        }
        #expect(didResubscribe)

        let reconnectResubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(reconnectResubscribeRequest["method"] as? String == subscribeMethod.path)
        let reconnectResubscribeIdentifier = try extractRequestIdentifier(from: reconnectResubscribeRequest)
        let reconnectResubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: reconnectResubscribeIdentifier,
            result: ["height": 940_000, "hex": String(repeating: "f", count: 160)]
        )
        await transport.enqueueIncoming(.data(reconnectResubscribePayload))

        await initialSubscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))

        let didClearInitialSubscription = await waitUntil(timeout: .seconds(5)) {
            await fulcrum.makeActiveSubscriptionStates().isEmpty
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
        let replacementSubscribeIdentifier = try extractRequestIdentifier(from: replacementSubscribeRequest)
        let replacementSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: replacementSubscribeIdentifier,
            result: ["height": 940_001, "hex": String(repeating: "1", count: 160)]
        )
        await transport.enqueueIncoming(.data(replacementSubscribePayload))

        let replacementSubscription = try await replacementSubscribeTask.value
        #expect(replacementSubscription.initial.height == 940_001)
        #expect(await fulcrum.makeActiveSubscriptionCount() == 1)

        await replacementSubscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(replacementSubscription.updates, within: .seconds(5)))

        await fulcrum.stop()
    }
}
