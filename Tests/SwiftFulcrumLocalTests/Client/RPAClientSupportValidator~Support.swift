// RPAClientSupportValidator~Support.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension RPAClientSupportValidator {
    struct RPAFeatureConfiguration: Sendable {
        let historyBlockLimit: Int
        let maximumHistoryItems: Int
        let indexedPrefixBits: Int
        let minimumPrefixBits: Int
        let startingHeight: Int

        init(
            historyBlockLimit: Int = 60,
            maximumHistoryItems: Int = 125_000,
            indexedPrefixBits: Int = 16,
            minimumPrefixBits: Int = 8,
            startingHeight: Int = 825_000
        ) {
            self.historyBlockLimit = historyBlockLimit
            self.maximumHistoryItems = maximumHistoryItems
            self.indexedPrefixBits = indexedPrefixBits
            self.minimumPrefixBits = minimumPrefixBits
            self.startingHeight = startingHeight
        }

        var jsonObject: [String: Any] {
            [
                "history_block_limit": historyBlockLimit,
                "max_history": maximumHistoryItems,
                "prefix_bits": indexedPrefixBits,
                "prefix_bits_min": minimumPrefixBits,
                "starting_height": startingHeight
            ]
        }
    }

    func makeStartedClient(
        negotiatedProtocolVersion: String = "1.6.0",
        rpa: RPAFeatureConfiguration? = .init()
    ) async throws -> (SwiftFulcrum.Client, TransportTestActor) {
        let transport = TransportTestActor()
        let networkClient = FulcrumNetworkClient(
            transport: transport,
            protocolNegotiation: .init()
        )
        let client = await SwiftFulcrum.Client(client: networkClient)
        let startTask = Task {
            try await client.start()
        }

        let versionRequest = try TransportTestActor.decodeJSONObject(
            from: await transport.dequeueOutgoing()
        )
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try extractRequestIdentifier(
            from: versionRequest
        )
        let versionResponse = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", negotiatedProtocolVersion]
        )
        await transport.enqueueIncoming(.data(versionResponse))

        let featuresRequest = try TransportTestActor.decodeJSONObject(
            from: await transport.dequeueOutgoing()
        )
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try extractRequestIdentifier(
            from: featuresRequest
        )
        var features: [String: Any] = [
            "genesis_hash": String(repeating: "0", count: 64),
            "hash_function": "sha256",
            "server_version": "SwiftFulcrum.Client 2.0",
            "protocol_max": "1.6.0",
            "protocol_min": "1.4.0"
        ]
        if let rpa {
            features["rpa"] = rpa.jsonObject
        }
        let featuresResponse = try TransportTestActor.encodeResponsePayload(
            identifier: featuresIdentifier,
            result: features
        )
        await transport.enqueueIncoming(.data(featuresResponse))

        try await startTask.value
        return (client, transport)
    }

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

    func extractRequestIdentifier(
        from request: [String: Any]
    ) throws -> String {
        try #require(request["id"] as? String)
    }
}
