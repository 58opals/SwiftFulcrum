// FulcrumClientLifecycleValidator~ReconnectObservationOrdering.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("delayed reconnecting observation preserves active recovery", .timeLimit(.minutes(1)))
    func preserveActiveRecoveryAfterDelayedReconnectObservation() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client

        await transport.pauseNextConnectionStateRead()
        await transport.configureConnectionState(.reconnecting)

        let didPauseReconnectStateConfirmation = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingConnectionStateReadCount() == 1
        }
        try #require(didPauseReconnectStateConfirmation)

        try await transport.reconnect(with: nil)
        await transport.enqueueLifecycleEvent(.connected(isReconnect: true))

        let didBeginRecovery = await waitUntil(timeout: .seconds(2)) {
            await networkClient.reconnectRecoveryState.recoveryTask != nil
        }
        try #require(didBeginRecovery)
        let recoveryTask = try #require(
            await networkClient.reconnectRecoveryState.recoveryTask
        )

        await transport.resumePendingConnectionStateReads()
        try await completeProtocolNegotiation(on: transport)
        try await recoveryTask.value

        #expect(await networkClient.reconnectRecoveryState.needsRecovery == false)
        #expect(await transport.connectionState == .connected)

        await fulcrum.stop()
    }

    @Test("request waits when reconnect observation is delayed", .timeLimit(.minutes(1)))
    func holdRequestUntilDelayedReconnectObservationCompletesRecovery() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))
        let requestMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))

        let subscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod)
        }
        let subscribeRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 935_000, "hex": String(repeating: "7", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))
        let subscription = try await subscribeTask.value

        await transport.pauseNextConnectionStateRead()
        try await transport.reconnect(with: nil)
        let didPauseReconnectStateConfirmation = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingConnectionStateReadCount() == 1
        }
        try #require(didPauseReconnectStateConfirmation)
        await transport.configureConnectionState(.connected)

        let requestTask = Task {
            try await fulcrum.request(
                method: requestMethod,
                responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self
            )
        }

        let versionRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(versionRequest["method"] as? String == "server.version")
        await transport.resumePendingConnectionStateReads()
        let versionIdentifier = try extractRequestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
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

        let restoreRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(restoreRequest["method"] as? String == subscribeMethod.path)
        let didSendRequestEarly = await waitUntil(timeout: .milliseconds(150)) {
            let requestCount = (try? await countSentMethodOccurrences(
                requestMethod.path,
                transport: transport
            )) ?? 0
            return requestCount > 0
        }
        #expect(didSendRequestEarly == false)

        let restoreIdentifier = try extractRequestIdentifier(from: restoreRequest)
        let restorePayload = try TransportTestActor.encodeResponsePayload(
            identifier: restoreIdentifier,
            result: ["height": 935_001, "hex": String(repeating: "8", count: 160)]
        )
        await transport.enqueueIncoming(.data(restorePayload))

        let request = try await dequeueNextRequestObject(
            matching: requestMethod.path,
            transport: transport
        )
        let requestIdentifier = try extractRequestIdentifier(from: request)
        let requestPayload = try TransportTestActor.encodeResponsePayload(
            identifier: requestIdentifier,
            result: ["height": 935_002, "hex": String(repeating: "9", count: 160)]
        )
        await transport.enqueueIncoming(.data(requestPayload))

        #expect(try await requestTask.value.height == 935_002)
        await subscription.cancel()
        await fulcrum.stop()
    }
}
