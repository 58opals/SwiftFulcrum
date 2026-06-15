// ResponseDecodingValidator~Support.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    func makeJSONData(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object)
    }

    func makeReusablePaymentAddressFeatureOverrides(_ overrides: [String: Any]) -> [String: Any] {
        var reusablePaymentAddress: [String: Any] = [
            "history_block_limit": 1_000,
            "max_history": 100,
            "prefix_bits": 20,
            "prefix_bits_min": 8,
            "starting_height": 0
        ]
        for (key, value) in overrides {
            reusablePaymentAddress[key] = value
        }
        return ["rpa": reusablePaymentAddress]
    }

    func expectResponseResultDecodeFailure<DecodedResponse: Decodable & Sendable>(
        _ responseType: DecodedResponse.Type,
        from payload: Data,
        methodPath: String
    ) {
        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(responseType, context: .init(methodPath: methodPath))
        }
    }

    func expectServerFeaturesResultDecodeFailure(_ resultOverrides: [String: Any]) throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": makeServerFeaturesResult(resultOverrides)
            ]
        )

        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Server.Features.self,
            from: payload,
            methodPath: "server.features"
        )
    }

    func expectVerboseTransactionDecodeFailure(_ payload: Data) {
        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.Verbose.self,
                context: .init(methodPath: "blockchain.transaction.get")
            )
        }
    }

    func expectDSProofLookupDecodeFailure(from payload: Data) {
        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Lookup.self,
            from: payload,
            methodPath: "blockchain.transaction.dsproof.get"
        )
    }

    func makeServerFeaturesResult(_ overrides: [String: Any] = [:]) -> [String: Any] {
        var result: [String: Any] = [
            "genesis_hash": String(repeating: "0", count: 64),
            "hash_function": "sha256",
            "server_version": "Fulcrum 2.0",
            "protocol_max": "1.6.0",
            "protocol_min": "1.4.0"
        ]

        for (key, value) in overrides {
            result[key] = value
        }

        return result
    }

    func makeDSProofResult(
        transactionHash: String,
        doubleSpendProofIdentifier: String = String(repeating: "1", count: 64),
        hex: String = "00",
        outpointTransactionHash: String = String(repeating: "0", count: 64),
        descendants: [String] = []
    ) -> [String: Any] {
        [
            "dspid": doubleSpendProofIdentifier,
            "txid": transactionHash,
            "hex": hex,
            "outpoint": ["txid": outpointTransactionHash, "vout": 1],
            "descendants": descendants
        ]
    }

    func makeDSProofLookupPayload(_ result: [String: Any]) throws -> Data {
        try makeJSONData([
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "result": result
        ])
    }

    func makeVerboseTransactionPayload(resultOverrides: [String: Any] = [:]) throws -> Data {
        let transactionHash = "36a3692a41a8ac60b73f7f41ee23f5c917413e5b2fad9e44b34865bd0d601a3d"
        var result: [String: Any] = [
            "hash": transactionHash,
            "hex": "01000000",
            "locktime": 0,
            "size": 225,
            "txid": transactionHash,
            "version": 1,
            "vin": [],
            "vout": []
        ]

        for (key, value) in resultOverrides {
            result[key] = value
        }

        return try makeJSONData([
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "result": result
        ])
    }

    func makeVerboseTransactionPayload(output: [String: Any]) throws -> Data {
        try makeVerboseTransactionPayload(resultOverrides: ["vout": [output]])
    }

    func makeVerboseTransactionInput(
        transactionHash: String = "5bb9142c960a838329694d3fe9ba08c2a6421c5158d8f7044cb7c48006c1b484",
        scriptSigHex: String = "160014deadbeef"
    ) -> [String: Any] {
        [
            "scriptSig": [
                "asm": "0014deadbeef",
                "hex": scriptSigHex
            ],
            "sequence": 4_294_967_295,
            "txid": transactionHash,
            "vout": 0
        ]
    }

    func makeVerboseTransactionOutput(
        scriptPubKeyHex: String = "76a914deadbeef88ac",
        scriptPubKeyOverrides: [String: Any] = [:],
        value: Double = 1.25
    ) -> [String: Any] {
        var scriptPubKey: [String: Any] = [
            "asm": "OP_DUP OP_HASH160 deadbeef OP_EQUALVERIFY OP_CHECKSIG",
            "hex": scriptPubKeyHex,
            "type": "pubkeyhash"
        ]
        for (key, value) in scriptPubKeyOverrides {
            scriptPubKey[key] = value
        }

        return [
            "n": 0,
            "scriptPubKey": scriptPubKey,
            "value": value
        ]
    }
}
