// ResponseDecodingValidator~DSProofLookup.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Rejects DSProof lookup payloads with malformed transaction hashes")
    func rejectDSProofLookupPayloadsWithMalformedTransactionHashes() throws {
        let payload = try makeDSProofLookupPayload(makeDSProofResult(transactionHash: "abc123"))

        expectDSProofLookupDecodeFailure(from: payload)
    }

    @Test(
        "Rejects DSProof lookup payloads with malformed proof identifiers",
        arguments: [
            ("short identifier", "proof-id"),
            ("non-hex identifier", String(repeating: "g", count: 64))
        ]
    )
    func rejectDSProofLookupPayloadsWithMalformedProofIdentifiers(
        _ caseDescription: String,
        _ doubleSpendProofIdentifier: String
    ) throws {
        let payload = try makeDSProofLookupPayload(
            makeDSProofResult(
                transactionHash: String(repeating: "a", count: 64),
                doubleSpendProofIdentifier: doubleSpendProofIdentifier
            )
        )

        expectDSProofLookupDecodeFailure(from: payload)
    }

    @Test("Rejects DSProof lookup payloads with malformed outpoint hashes")
    func rejectDSProofLookupPayloadsWithMalformedOutpointHashes() throws {
        let payload = try makeDSProofLookupPayload(
            makeDSProofResult(
                transactionHash: String(repeating: "a", count: 64),
                outpointTransactionHash: "prev"
            )
        )

        expectDSProofLookupDecodeFailure(from: payload)
    }

    @Test("Rejects DSProof lookup payloads with malformed descendant hashes")
    func rejectDSProofLookupPayloadsWithMalformedDescendantHashes() throws {
        let payload = try makeDSProofLookupPayload(
            makeDSProofResult(
                transactionHash: String(repeating: "a", count: 64),
                descendants: ["child"]
            )
        )

        expectDSProofLookupDecodeFailure(from: payload)
    }

    @Test(
        "Rejects DSProof lookup payloads with malformed proof hex",
        arguments: [
            ("empty proof hex", ""),
            ("non-hex proof hex", "zz")
        ]
    )
    func rejectDSProofLookupPayloadsWithMalformedProofHex(_ caseDescription: String, _ proofHex: String) throws {
        let payload = try makeDSProofLookupPayload(
            makeDSProofResult(
                transactionHash: String(repeating: "a", count: 64),
                hex: proofHex
            )
        )

        expectDSProofLookupDecodeFailure(from: payload)
    }

    @Test(
        "Rejects DSProof list payloads with malformed transaction hashes",
        arguments: [
            "abc123",
            String(repeating: "g", count: 64)
        ]
    )
    func rejectDSProofListPayloadsWithMalformedTransactionHashes(_ transactionHash: String) throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    String(repeating: "a", count: 64),
                    transactionHash
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.DSProof.List.self,
                context: .init(methodPath: "blockchain.transaction.dsproof.list")
            )
        }
    }
}
