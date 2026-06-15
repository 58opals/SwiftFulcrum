// ResponseDecodingValidator~ServerMetadata.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Decodes server.version and server.features")
    func decodeServerMetadataResponses() throws {
        let versionPayload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": ["Fulcrum 2.0", "1.5.3"]]
        )
        let version = try versionPayload.decode(
            SwiftFulcrum.Response.Server.Version.self,
            context: .init(methodPath: "server.version")
        )
        #expect(version.serverVersion == "Fulcrum 2.0")
        #expect(version.negotiatedProtocolVersion == SwiftFulcrum.ProtocolVersion(string: "1.5.3"))

        let featuresPayload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": makeServerFeaturesResult([
                    "cashtokens": true,
                    "dsproof": true
                ])
            ]
        )
        let features = try featuresPayload.decode(
            SwiftFulcrum.Response.Server.Features.self,
            context: .init(methodPath: "server.features")
        )
        #expect(features.maximumProtocolVersion == SwiftFulcrum.ProtocolVersion(string: "1.6.0"))
        #expect(features.minimumProtocolVersion == SwiftFulcrum.ProtocolVersion(string: "1.4.0"))
        #expect(features.hasCashTokens == true)
        #expect(features.hasDoubleSpendProofs == true)
    }

    @Test("Rejects server.features with an inverted protocol range")
    func rejectServerFeaturesWithInvertedProtocolRange() throws {
        try expectServerFeaturesResultDecodeFailure([
            "protocol_max": "1.4.0",
            "protocol_min": "1.6.0"
        ])
    }

    @Test("Rejects server.features with malformed genesis hashes")
    func rejectServerFeaturesWithMalformedGenesisHashes() throws {
        try expectServerFeaturesResultDecodeFailure([
            "genesis_hash": String(repeating: "g", count: 64)
        ])
    }

    @Test(
        "Rejects server.features with unsupported hash functions",
        arguments: [
            "sha512",
            "SHA256"
        ]
    )
    func rejectServerFeaturesWithUnsupportedHashFunctions(_ hashFunction: String) throws {
        try expectServerFeaturesResultDecodeFailure(["hash_function": hashFunction])
    }

    @Test(
        "Rejects server.features host ports outside the valid range",
        arguments: [-1, 0, 65_536]
    )
    func rejectServerFeaturesHostPortsOutsideValidRange(_ port: Int) throws {
        try expectServerFeaturesResultDecodeFailure([
            "hosts": [
                "invalid.fulcrum.example": ["wss_port": port]
            ]
        ])
    }

    @Test(
        "Rejects server.features with invalid host names",
        arguments: [
            ("blank host name", " "),
            ("leading newline host name", "\ninvalid.fulcrum.example"),
            ("embedded whitespace host name", "invalid fulcrum.example"),
            ("padded host name", " invalid.fulcrum.example ")
        ]
    )
    func rejectServerFeaturesWithInvalidHostNames(_ caseDescription: String, _ hostName: String) throws {
        try expectServerFeaturesResultDecodeFailure([
            "hosts": [
                hostName: ["wss_port": 50004]
            ]
        ])
    }

    @Test("Rejects server.features negative pruning limits")
    func rejectServerFeaturesNegativePruningLimits() throws {
        try expectServerFeaturesResultDecodeFailure(["pruning": -1])
    }

    @Test(
        "Rejects server.features reusable payment address negative values",
        arguments: [
            "history_block_limit",
            "max_history",
            "prefix_bits",
            "prefix_bits_min",
            "starting_height"
        ]
    )
    func rejectServerFeaturesReusablePaymentAddressNegativeValues(_ field: String) throws {
        try expectServerFeaturesResultDecodeFailure(makeReusablePaymentAddressFeatureOverrides([field: -1]))
    }

    @Test("Rejects server.features reusable payment address inverted prefix ranges")
    func rejectServerFeaturesReusablePaymentAddressInvertedPrefixRanges() throws {
        try expectServerFeaturesResultDecodeFailure(
            makeReusablePaymentAddressFeatureOverrides(["prefix_bits": 8, "prefix_bits_min": 20])
        )
    }

    @Test("Rejects server.version arrays with extra fields")
    func rejectServerVersionArraysWithExtraFields() throws {
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": ["Fulcrum 2.0", "1.5.3", "extra"]]
        )

        #expect(throws: DecodingError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Server.Version.self,
                context: .init(methodPath: "server.version")
            )
        }
    }
}
