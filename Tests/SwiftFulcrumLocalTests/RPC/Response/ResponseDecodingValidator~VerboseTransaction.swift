// ResponseDecodingValidator~VerboseTransaction.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Decodes verbose mempool transactions without confirmation metadata")
    func decodeVerboseMempoolTransactionWithoutConfirmationMetadata() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "hash": "36a3692a41a8ac60b73f7f41ee23f5c917413e5b2fad9e44b34865bd0d601a3d",
                    "hex": "01000000",
                    "locktime": 0,
                    "size": 225,
                    "txid": "36a3692a41a8ac60b73f7f41ee23f5c917413e5b2fad9e44b34865bd0d601a3d",
                    "version": 1,
                    "vin": [
                        [
                            "scriptSig": [
                                "asm": "0014deadbeef",
                                "hex": "160014deadbeef"
                            ],
                            "sequence": 4_294_967_295,
                            "txid": "5bb9142c960a838329694d3fe9ba08c2a6421c5158d8f7044cb7c48006c1b484",
                            "vout": 0
                        ]
                    ],
                    "vout": [
                        [
                            "n": 0,
                            "scriptPubKey": [
                                "asm": "OP_DUP OP_HASH160 deadbeef OP_EQUALVERIFY OP_CHECKSIG",
                                "hex": "76a914deadbeef88ac",
                                "type": "pubkeyhash"
                            ],
                            "value": 1.25
                        ]
                    ]
                ]
            ]
        )

        let transaction = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.Verbose.self,
            context: .init(methodPath: "blockchain.transaction.get")
        )

        #expect(transaction.blockHash == nil)
        #expect(transaction.blocktime == nil)
        #expect(transaction.confirmations == nil)
        #expect(transaction.time == nil)
        #expect(transaction.transactionID == "36a3692a41a8ac60b73f7f41ee23f5c917413e5b2fad9e44b34865bd0d601a3d")
        #expect(transaction.inputs.count == 1)
        #expect(transaction.outputs.count == 1)
    }

    @Test("Rejects verbose transaction payloads with malformed hashes")
    func rejectVerboseTransactionPayloadsWithMalformedHashes() throws {
        let malformedTopLevelPayload = try makeVerboseTransactionPayload(
            resultOverrides: ["hash": "transaction"]
        )

        expectVerboseTransactionDecodeFailure(malformedTopLevelPayload)

        let malformedInputPayload = try makeVerboseTransactionPayload(
            resultOverrides: [
                "vin": [
                    makeVerboseTransactionInput(
                        transactionHash: "5bb9142c960a838329694d3fe9ba08c2a6421c5158d8f7044cb7c48006c1b48"
                    )
                ]
            ]
        )

        expectVerboseTransactionDecodeFailure(malformedInputPayload)
    }

    @Test(
        "Rejects verbose transaction payloads with malformed transaction hex",
        arguments: [
            ("empty transaction hex", ""),
            ("non-hex transaction hex", "0100000z"),
            ("odd-length transaction hex", "0100000")
        ]
    )
    func rejectVerboseTransactionPayloadsWithMalformedTransactionHex(_ caseDescription: String, _ transactionHex: String) throws {
        let payload = try makeVerboseTransactionPayload(
            resultOverrides: ["hex": transactionHex]
        )

        expectVerboseTransactionDecodeFailure(payload)
    }

    @Test(
        "Rejects verbose transaction inputs with malformed scriptSig hex",
        arguments: ["160014zz", "160014d"]
    )
    func rejectVerboseTransactionInputsWithMalformedScriptSigHex(_ scriptSigHex: String) throws {
        let payload = try makeVerboseTransactionPayload(
            resultOverrides: [
                "vin": [
                    makeVerboseTransactionInput(scriptSigHex: scriptSigHex)
                ]
            ]
        )

        expectVerboseTransactionDecodeFailure(payload)
    }

    @Test("Rejects verbose transaction outputs with malformed scriptPubKey hex")
    func rejectVerboseTransactionOutputsWithMalformedScriptPubKeyHex() throws {
        let payload = try makeVerboseTransactionPayload(
            output: makeVerboseTransactionOutput(scriptPubKeyHex: "76a914zz")
        )

        expectVerboseTransactionDecodeFailure(payload)
    }

    @Test("Rejects verbose transaction outputs with ambiguous scriptPubKey addresses")
    func rejectVerboseTransactionOutputsWithAmbiguousScriptPubKeyAddresses() throws {
        let payload = try makeVerboseTransactionPayload(
            output: makeVerboseTransactionOutput(
                scriptPubKeyOverrides: [
                    "address": "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a",
                    "addresses": ["bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"]
                ]
            )
        )

        expectVerboseTransactionDecodeFailure(payload)
    }

    @Test("Rejects verbose transaction outputs with negative values")
    func rejectVerboseTransactionOutputsWithNegativeValues() throws {
        let payload = try makeVerboseTransactionPayload(
            output: makeVerboseTransactionOutput(value: -0.01)
        )

        expectVerboseTransactionDecodeFailure(payload)
    }

    @Test("Rejects raw transaction payloads when verbose details are expected without echoing hex")
    func rejectRawTransactionPayloadWhenVerboseDetailsAreExpectedWithoutEchoingHex() throws {
        let rawHex = "01000000deadbeef"
        let payload = try makeJSONData([
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "result": rawHex
        ])

        do {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.Verbose.self,
                context: .init(methodPath: "blockchain.transaction.get")
            )
            Issue.record("Expected raw transaction payload to fail verbose decoding")
        } catch let error as ResponseResultDecodeError {
            guard case .unexpectedFormat(let message) = error else {
                Issue.record("Expected unexpected format, got \(error)")
                return
            }
            #expect(message.contains(rawHex) == false)
            #expect(message.contains("raw transaction hex payload"))
            #expect(message.contains("\(rawHex.utf8.count) UTF-8 bytes"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
