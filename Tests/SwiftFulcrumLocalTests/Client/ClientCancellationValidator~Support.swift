// ClientCancellationValidator~Support.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientCancellationValidator {
    func captureClientError(
        operation: () async throws -> Void
    ) async -> SwiftFulcrum.Client.Error {
        do {
            try await operation()
            Issue.record("Operation should throw a SwiftFulcrum.Client.Error.")
            return .client(.unknown(nil))
        } catch let error as SwiftFulcrum.Client.Error {
            return error
        } catch {
            Issue.record("Unexpected non-SwiftFulcrum.Client error: \(error)")
            return .client(.unknown(error))
        }
    }

    func isCancelledError(_ error: SwiftFulcrum.Client.Error) -> Bool {
        if case .client(.cancelled) = error {
            return true
        }

        return false
    }

    func isTimeoutError(_ error: SwiftFulcrum.Client.Error) -> Bool {
        if case .client(.timeout) = error {
            return true
        }

        return false
    }

    func makeStartedFulcrum() async throws -> (SwiftFulcrum.Client, TransportTestActor) {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await SwiftFulcrum.Client(client: client)
        try await startAndNegotiate(fulcrum, transport: transport)
        return (fulcrum, transport)
    }

    func startAndNegotiate(_ fulcrum: SwiftFulcrum.Client, transport: TransportTestActor) async throws {
        let startTask = Task { try await fulcrum.start() }

        let versionObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let versionIdentifier = try extractRequestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let featuresIdentifier = try extractRequestIdentifier(from: featuresObject)
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

    func extractRequestIdentifier(from object: [String: Any]) throws -> String {
        guard let identifier = object["id"] as? String else {
            throw SupportError.missingRequestIdentifier
        }

        return identifier
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
