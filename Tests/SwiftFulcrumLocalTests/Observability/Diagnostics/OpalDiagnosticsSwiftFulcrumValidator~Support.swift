// OpalDiagnosticsSwiftFulcrumValidator~Support.swift

import Foundation
import OpalDiagnostics
import Testing
@testable import SwiftFulcrum

extension OpalDiagnosticsSwiftFulcrumValidator {
    static var diagnosticsConfiguration: OpalDiagnostics.Configuration {
        .init(
            minimumLevel: .debug,
            categoryFilter: .enabledIncludingSubcategories([.fulcrum]),
            bufferPolicy: .enabled(capacity: 10_000)
        )
    }

    func withDiagnosticsCapture<Success>(_ operation: () throws -> Success) rethrows -> Success {
        try OpalDiagnostics.withConfiguration(Self.diagnosticsConfiguration) {
            OpalDiagnostics.clearRecentRecords()
            return try operation()
        }
    }

    func withDiagnosticsCapture<Success>(_ operation: () async throws -> Success) async rethrows -> Success {
        try await OpalDiagnostics.withConfiguration(Self.diagnosticsConfiguration) {
            OpalDiagnostics.clearRecentRecords()
            return try await operation()
        }
    }

    func findDiagnosticRecord(
        named event: OpalDiagnostics.Event,
        traceID: OpalDiagnostics.TraceID? = nil
    ) -> OpalDiagnostics.Record? {
        OpalDiagnostics.recentRecords(matching: .init(traceID: traceID, event: event)).first
    }

    func findField(_ name: String, in record: OpalDiagnostics.Record) -> OpalDiagnostics.Field? {
        record.fields.first { $0.name == name }
    }

    func makeJSONData(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    func makeRequestIdentifier(from object: [String: Any]) throws -> UUID {
        let rawIdentifier = try #require(object["id"] as? String)
        return try #require(UUID(uuidString: rawIdentifier))
    }

    func startAndCompleteProtocolNegotiation(
        client: FulcrumNetworkClient,
        transport: TransportTestActor
    ) async throws {
        let startTask = Task {
            try await client.start()
        }
        try await completeProtocolNegotiation(transport: transport)
        try await startTask.value
    }

    func completeProtocolNegotiation(transport: TransportTestActor) async throws {
        let versionRequest = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try makeRequestIdentifier(from: versionRequest)
        let versionPayload = try makeJSONData([
            "jsonrpc": "2.0",
            "id": versionIdentifier.uuidString,
            "result": ["SwiftFulcrum.Client 2.0", "1.5.3"]
        ])
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try makeRequestIdentifier(from: featuresRequest)
        let featuresPayload = try makeJSONData([
            "jsonrpc": "2.0",
            "id": featuresIdentifier.uuidString,
            "result": [
                "genesis_hash": String(repeating: "0", count: 64),
                "hash_function": "sha256",
                "server_version": "SwiftFulcrum.Client 2.0",
                "protocol_max": "1.6.0",
                "protocol_min": "1.4.0"
            ]
        ])
        await transport.enqueueIncoming(.data(featuresPayload))
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
