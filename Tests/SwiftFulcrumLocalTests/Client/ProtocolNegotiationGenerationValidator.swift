// ProtocolNegotiationGenerationValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ProtocolNegotiationGenerationValidator {
    @Test("stale negotiation cannot overwrite its replacement", .timeLimit(.minutes(1)))
    func preventStaleNegotiationFromOverwritingReplacement() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(
            transport: transport,
            protocolNegotiation: .init()
        )
        await client.startReceivingTask()

        let firstNegotiation = Task {
            try await client.ensureNegotiatedProtocol()
        }
        let firstVersionRequest = try decodeRequest(
            await transport.dequeueOutgoing(),
            expectedMethod: "server.version"
        )

        await transport.configureOutgoingSendPaused(true)
        try await respond(
            to: firstVersionRequest,
            result: ["Generation A", "1.5.3"],
            using: transport
        )
        let didPauseFirstFeaturesRequest = await waitUntil {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(didPauseFirstFeaturesRequest)

        await client.resetNegotiatedSession()

        let secondNegotiation = Task {
            try await client.ensureNegotiatedProtocol()
        }
        let didPauseBothGenerations = await waitUntil {
            await transport.makePendingOutgoingSendCount() == 2
        }
        #expect(didPauseBothGenerations)

        await transport.configureOutgoingSendPaused(false)

        let secondVersionRequest = try decodeRequest(
            await transport.dequeueOutgoing(),
            expectedMethod: "server.version"
        )
        try await respond(
            to: secondVersionRequest,
            result: ["Generation B", "1.5.3"],
            using: transport
        )

        let secondFeaturesRequest = try decodeRequest(
            await transport.dequeueOutgoing(),
            expectedMethod: "server.features"
        )
        try await respond(
            to: secondFeaturesRequest,
            result: [
                "genesis_hash": String(repeating: "0", count: 64),
                "hash_function": "sha256",
                "server_version": "Generation B",
                "protocol_max": "1.6.0",
                "protocol_min": "1.4.0"
            ],
            using: transport
        )

        let negotiatedSession = try await secondNegotiation.value
        #expect(negotiatedSession.serverSoftwareVersion == "Generation B")

        await #expect(throws: CancellationError.self) {
            try await firstNegotiation.value
        }

        let finalSession = await client.state.negotiatedSession
        #expect(finalSession.serverSoftwareVersion == "Generation B")
        #expect(finalSession.negotiationWaiterCount == 0)

        await client.cancelBackgroundTasks()
    }

    private func decodeRequest(
        _ message: URLSessionWebSocketTask.Message,
        expectedMethod: String
    ) throws -> [String: Any] {
        let request = try TransportTestActor.decodeJSONObject(from: message)
        #expect(request["method"] as? String == expectedMethod)
        return request
    }

    private func respond(
        to request: [String: Any],
        result: Any,
        using transport: TransportTestActor
    ) async throws {
        let identifier = try #require(request["id"] as? String)
        let payload = try TransportTestActor.encodeResponsePayload(
            identifier: identifier,
            result: result
        )
        await transport.enqueueIncoming(.data(payload))
    }

    private func waitUntil(
        timeout: Duration = .seconds(2),
        _ condition: @Sendable @escaping () async -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while clock.now < deadline {
            if await condition() {
                return true
            }
            try? await Task.sleep(for: .milliseconds(25))
        }

        return await condition()
    }
}
