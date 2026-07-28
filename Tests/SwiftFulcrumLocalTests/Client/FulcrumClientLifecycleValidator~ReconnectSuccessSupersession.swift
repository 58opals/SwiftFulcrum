// FulcrumClientLifecycleValidator~ReconnectSuccessSupersession.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("newer reconnect success supersedes active recovery", .timeLimit(.minutes(1)))
    func recoverNewerReconnectBeforeReleasingReadiness() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client

        await transport.pauseNextConnectionStateRead()
        try await transport.reconnect(with: nil)
        let didPauseFirstReconnectObservation = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingConnectionStateReadCount() == 1
        }
        try #require(didPauseFirstReconnectObservation)
        await transport.configureConnectionState(.connected)
        let firstReconnectSuccessCount = await transport.reconnectSuccesses
        let firstRecoveryTask = try #require(
            await networkClient.beginAutomaticReconnectRecovery(
                reconnectSuccessCount: firstReconnectSuccessCount
            )
        )
        await transport.resumePendingConnectionStateReads()

        let firstVersionRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        try await respondToProtocolRequest(
            firstVersionRequest,
            result: ["Generation A", "1.5.3"],
            transport: transport
        )
        let firstFeaturesRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        let versionRequestCountAfterFirstRecovery = try await countSentMethodOccurrences(
            "server.version",
            transport: transport
        )

        await transport.pauseNextConnectionStateRead()
        try await transport.reconnect(with: nil)
        let didPauseSecondReconnectObservation = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingConnectionStateReadCount() == 1
        }
        try #require(didPauseSecondReconnectObservation)
        await transport.configureConnectionState(.connected)

        let readinessCompletion = ReconnectCompletionState()
        let readinessTask = Task {
            do {
                try await networkClient.awaitReconnectReadiness()
                await readinessCompletion.markCompleted()
            } catch {
                await readinessCompletion.markCompleted()
                throw error
            }
        }

        try await respondToProtocolRequest(
            firstFeaturesRequest,
            result: makeServerFeatures(serverVersion: "Generation A"),
            transport: transport
        )
        await #expect(throws: CancellationError.self) {
            try await firstRecoveryTask.value
        }

        let didStartReplacementRecovery = await waitUntil(timeout: .seconds(2)) {
            let versionRequestCount = (try? await countSentMethodOccurrences(
                "server.version",
                transport: transport
            )) ?? versionRequestCountAfterFirstRecovery
            return versionRequestCount > versionRequestCountAfterFirstRecovery
        }
        try #require(didStartReplacementRecovery)
        #expect(await readinessCompletion.isCompleted == false)
        await transport.resumePendingConnectionStateReads()

        let secondVersionRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        try await respondToProtocolRequest(
            secondVersionRequest,
            result: ["Generation B", "1.5.3"],
            transport: transport
        )
        let secondFeaturesRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        try await respondToProtocolRequest(
            secondFeaturesRequest,
            result: makeServerFeatures(serverVersion: "Generation B"),
            transport: transport
        )

        try await readinessTask.value
        #expect(await readinessCompletion.isCompleted)
        #expect(
            await networkClient.state.negotiatedSession.serverSoftwareVersion
                == "Generation B"
        )
        await fulcrum.stop()
    }

    private func respondToProtocolRequest(
        _ request: [String: Any],
        result: Any,
        transport: TransportTestActor
    ) async throws {
        let identifier = try extractRequestIdentifier(from: request)
        let payload = try TransportTestActor.encodeResponsePayload(
            identifier: identifier,
            result: result
        )
        await transport.enqueueIncoming(.data(payload))
    }

    private func makeServerFeatures(serverVersion: String) -> [String: Any] {
        [
            "genesis_hash": String(repeating: "0", count: 64),
            "hash_function": "sha256",
            "server_version": serverVersion,
            "protocol_max": "1.6.0",
            "protocol_min": "1.4.0"
        ]
    }
}
