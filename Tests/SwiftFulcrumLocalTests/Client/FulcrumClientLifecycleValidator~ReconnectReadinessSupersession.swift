// FulcrumClientLifecycleValidator~ReconnectReadinessSupersession.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("superseded automatic reconnect recovery does not disconnect transport", .timeLimit(.minutes(1)))
    func preserveTransportWhenAutomaticReconnectRecoveryIsSuperseded() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client

        let recoveryTask = await networkClient.makeOrReuseAutomaticReconnectRecoveryTask()

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")

        await networkClient.prepareForAutomaticReconnectRecovery()

        await #expect(throws: CancellationError.self) {
            try await recoveryTask.value
        }

        #expect(await transport.connectionState == .connected)

        await fulcrum.stop()
    }

    @Test("reconnect readiness waits for superseding recovery", .timeLimit(.minutes(1)))
    func waitForSupersedingRecoveryDuringReconnectReadiness() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client

        let firstRecoveryTask = await networkClient.makeOrReuseAutomaticReconnectRecoveryTask()

        let firstVersionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(firstVersionRequest["method"] as? String == "server.version")

        let readinessTask = Task {
            try await networkClient.awaitReconnectReadiness()
        }
        try? await Task.sleep(for: .milliseconds(50))

        await networkClient.prepareForAutomaticReconnectRecovery()
        await #expect(throws: CancellationError.self) {
            try await firstRecoveryTask.value
        }

        let secondVersionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(secondVersionRequest["method"] as? String == "server.version")
        let secondVersionIdentifier = try extractRequestIdentifier(from: secondVersionRequest)
        let secondVersionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: secondVersionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(secondVersionPayload))

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

        try await readinessTask.value

        await fulcrum.stop()
    }
}
