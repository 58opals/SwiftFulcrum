// FulcrumClientLifecycleValidator~ReconnectReadiness.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("request remains usable after reconnect negotiation completes", .timeLimit(.minutes(1)))
    func requestRemainsUsableAfterReconnectNegotiationCompletes() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))
        let requestMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))

        let subscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod, options: .init(timeout: .seconds(30)))
        }

        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
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
        let restoreIdentifier = try extractRequestIdentifier(from: restoreRequest)

        let requestTask = Task {
            try await fulcrum.request(
                method: requestMethod,
                responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
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

        let request = try await dequeueNextRequestObject(
            matching: requestMethod.path,
            transport: transport
        )
        let requestIdentifier = try extractRequestIdentifier(from: request)
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
                responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
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

        let request = try await dequeueNextRequestObject(
            matching: requestMethod.path,
            transport: transport
        )
        let requestIdentifier = try extractRequestIdentifier(from: request)
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
}
