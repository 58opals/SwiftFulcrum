// FulcrumClientLifecycleValidator~ManualReconnectSupersession.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("new connection supersedes manual reconnect recovery", .timeLimit(.minutes(1)))
    func recoverConnectionThatSupersedesManualReconnect() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client
        let requestMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))

        let reconnectTask = Task {
            try await fulcrum.reconnect()
        }
        let firstVersionRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        let firstVersionIdentifier = try extractRequestIdentifier(
            from: firstVersionRequest
        )
        let firstVersionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: firstVersionIdentifier,
            result: ["Generation A", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(firstVersionPayload))
        let firstFeaturesRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(firstFeaturesRequest["method"] as? String == "server.features")

        try await transport.reconnect(with: nil)
        await transport.configureConnectionState(.connected)
        await transport.enqueueLifecycleEvent(
            .connected(isReconnect: true)
        )

        let secondVersionRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(secondVersionRequest["method"] as? String == "server.version")
        let secondVersionIdentifier = try extractRequestIdentifier(
            from: secondVersionRequest
        )
        let secondVersionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: secondVersionIdentifier,
            result: ["Generation B", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(secondVersionPayload))

        let secondFeaturesRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        let secondFeaturesIdentifier = try extractRequestIdentifier(
            from: secondFeaturesRequest
        )
        let secondFeaturesPayload = try TransportTestActor.encodeResponsePayload(
            identifier: secondFeaturesIdentifier,
            result: makeSupersessionFeatures(serverVersion: "Generation B")
        )
        await transport.enqueueIncoming(.data(secondFeaturesPayload))

        try await reconnectTask.value

        let requestTask = Task {
            try await fulcrum.request(
                method: requestMethod,
                responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self
            )
        }
        let request = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(request["method"] as? String == requestMethod.path)
        let requestIdentifier = try extractRequestIdentifier(from: request)
        let requestPayload = try TransportTestActor.encodeResponsePayload(
            identifier: requestIdentifier,
            result: ["height": 935_200, "hex": String(repeating: "b", count: 160)]
        )
        await transport.enqueueIncoming(.data(requestPayload))

        #expect(try await requestTask.value.height == 935_200)
        #expect(
            await networkClient.state.negotiatedSession.serverSoftwareVersion
                == "Generation B"
        )
        await fulcrum.stop()
    }

    private func makeSupersessionFeatures(
        serverVersion: String
    ) -> [String: Any] {
        [
            "genesis_hash": String(repeating: "0", count: 64),
            "hash_function": "sha256",
            "server_version": serverVersion,
            "protocol_max": "1.6.0",
            "protocol_min": "1.4.0"
        ]
    }
}
