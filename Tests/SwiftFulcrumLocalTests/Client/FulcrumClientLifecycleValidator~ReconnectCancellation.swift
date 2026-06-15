// FulcrumClientLifecycleValidator~ReconnectCancellation.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("cancel during reconnect restore completes without restore response", .timeLimit(.minutes(1)))
    func cancelDuringReconnectRestoreCompletesWithoutRestoreResponse() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))

        let subscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod, options: .init(timeout: .seconds(30)))
        }

        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
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
            await fulcrum.makeActiveSubscriptionStates().isEmpty
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
        let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
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
        let versionIdentifier = try extractRequestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let baselineOutgoingCount = await transport.sentMessages.count
        await transport.configureOutgoingSendPaused(true)

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
            await fulcrum.makeActiveSubscriptionStates().isEmpty
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
}
