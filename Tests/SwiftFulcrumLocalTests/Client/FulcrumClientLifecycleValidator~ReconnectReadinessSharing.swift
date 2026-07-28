// FulcrumClientLifecycleValidator~ReconnectReadinessSharing.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("automatic reconnect recovery is shared across concurrent waiters", .timeLimit(.minutes(1)))
    func shareAutomaticReconnectRecoveryAcrossConcurrentWaiters() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let requestMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))
        let baselineVersionCount = try await countSentMethodOccurrences(
            "server.version",
            transport: transport
        )
        let baselineFeaturesCount = try await countSentMethodOccurrences(
            "server.features",
            transport: transport
        )

        try await transport.reconnect(with: nil)

        let firstRequestTask = Task {
            try await fulcrum.request(
                method: requestMethod,
                responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
                options: .init(timeout: .seconds(30))
            )
        }
        let secondRequestTask = Task {
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
            firstRequestTask.cancel()
            secondRequestTask.cancel()
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

        let firstRequest = try await dequeueNextRequestObject(
            matching: requestMethod.path,
            transport: transport
        )
        let firstIdentifier = try extractRequestIdentifier(from: firstRequest)
        let firstPayload = try TransportTestActor.encodeResponsePayload(
            identifier: firstIdentifier,
            result: ["height": 936_101, "hex": String(repeating: "b", count: 160)]
        )
        await transport.enqueueIncoming(.data(firstPayload))

        let secondRequest = try await dequeueNextRequestObject(
            matching: requestMethod.path,
            transport: transport
        )
        let secondIdentifier = try extractRequestIdentifier(from: secondRequest)
        let secondPayload = try TransportTestActor.encodeResponsePayload(
            identifier: secondIdentifier,
            result: ["height": 936_102, "hex": String(repeating: "c", count: 160)]
        )
        await transport.enqueueIncoming(.data(secondPayload))

        let firstResult = try await firstRequestTask.value
        let secondResult = try await secondRequestTask.value
        #expect(Set([firstResult.height, secondResult.height]) == Set([936_101, 936_102]))

        let versionCount = try await countSentMethodOccurrences(
            "server.version",
            transport: transport
        )
        let featuresCount = try await countSentMethodOccurrences(
            "server.features",
            transport: transport
        )
        #expect(versionCount == baselineVersionCount + 1)
        #expect(featuresCount == baselineFeaturesCount + 1)

        await fulcrum.stop()
    }
}
