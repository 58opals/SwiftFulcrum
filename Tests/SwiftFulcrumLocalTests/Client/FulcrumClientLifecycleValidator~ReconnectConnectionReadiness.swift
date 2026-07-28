// FulcrumClientLifecycleValidator~ReconnectConnectionReadiness.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("recovery waits for the reconnecting transport", .timeLimit(.minutes(1)))
    func waitForReconnectingTransportBeforeStartingRecovery() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let requestMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))
        let baselineVersionRequestCount = try await countSentMethodOccurrences(
            "server.version",
            transport: transport
        )

        try await transport.reconnect(with: nil)
        let requestTask = Task {
            try await fulcrum.request(
                method: requestMethod,
                responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self
            )
        }

        let didStartNegotiationEarly = await waitUntil(timeout: .milliseconds(150)) {
            let versionRequestCount = (try? await countSentMethodOccurrences(
                "server.version",
                transport: transport
            )) ?? baselineVersionRequestCount
            return versionRequestCount > baselineVersionRequestCount
        }
        #expect(didStartNegotiationEarly == false)

        requestTask.cancel()
        await fulcrum.stop()
        _ = try? await requestTask.value
    }

    @Test("connecting transport still completes reconnect recovery", .timeLimit(.minutes(1)))
    func recoverSessionAfterConnectingTransportBecomesConnected() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let requestMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))

        await transport.pauseNextConnectionStateRead()
        try await transport.reconnect(with: nil)
        let didPauseReconnectObservation = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingConnectionStateReadCount() == 1
        }
        try #require(didPauseReconnectObservation)
        await transport.configureConnectionState(.connecting)

        let requestTask = Task {
            try await fulcrum.request(
                method: requestMethod,
                responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self
            )
        }
        await transport.configureConnectionState(.connected)

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

        let request = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(request["method"] as? String == requestMethod.path)
        let requestIdentifier = try extractRequestIdentifier(from: request)
        let requestPayload = try TransportTestActor.encodeResponsePayload(
            identifier: requestIdentifier,
            result: ["height": 935_100, "hex": String(repeating: "a", count: 160)]
        )
        await transport.enqueueIncoming(.data(requestPayload))

        #expect(try await requestTask.value.height == 935_100)
        await fulcrum.stop()
    }
}
