// ClientHeartbeatValidator~Support.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientHeartbeatValidator {
    func startAndNegotiate(client: FulcrumNetworkClient, transport: TransportTestActor) async throws {
        let startTask = Task { try await client.start() }

        let versionObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let versionIdentifier = try #require(versionObject["id"] as? String)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let featuresIdentifier = try #require(featuresObject["id"] as? String)
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

        _ = try await startTask.value
    }

    func countSentMethodOccurrences(
        _ methodPath: String,
        transport: TransportTestActor
    ) async throws -> Int {
        let messages = await transport.sentMessages
        return try messages.reduce(into: 0) { count, message in
            guard let data = message.dataPayload else { return }
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            if object["method"] as? String == methodPath {
                count += 1
            }
        }
    }

    func waitUntil(
        timeout: Duration,
        pollingInterval: Duration = .milliseconds(25),
        _ condition: @Sendable @escaping () async -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while clock.now < deadline {
            if await condition() {
                return true
            }
            try? await Task.sleep(for: pollingInterval)
        }

        return await condition()
    }
}
