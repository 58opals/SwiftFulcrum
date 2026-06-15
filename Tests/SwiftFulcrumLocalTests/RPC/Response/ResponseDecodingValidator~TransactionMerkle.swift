// ResponseDecodingValidator~TransactionMerkle.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Decodes transaction.id_from_pos without a merkle proof")
    func decodeTransactionIDFromPosWithoutMerkleProof() throws {
        let transactionHash = String(repeating: "f", count: 64)
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": transactionHash]
        )

        let result = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.IDFromPos.self,
            context: .init(methodPath: "blockchain.transaction.id_from_pos")
        )

        #expect(result.transactionHash == transactionHash)
        #expect(result.merkle.isEmpty)
    }

    @Test("Rejects transaction.id_from_pos responses with malformed transaction hashes")
    func rejectTransactionIDFromPosWithMalformedTransactionHashes() throws {
        let barePayload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": String(repeating: "f", count: 63)]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try barePayload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.IDFromPos.self,
                context: .init(methodPath: "blockchain.transaction.id_from_pos")
            )
        }

        let proofPayload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "merkle": [],
                    "tx_hash": String(repeating: "f", count: 63)
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try proofPayload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.IDFromPos.self,
                context: .init(methodPath: "blockchain.transaction.id_from_pos")
            )
        }
    }

    @Test("Decodes transaction merkle proof")
    func decodeTransactionMerkleProof() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "merkle": [String(repeating: "a", count: 64), String(repeating: "b", count: 64)],
                    "block_height": 3,
                    "pos": 1
                ]
            ]
        )

        let result = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.Merkle.self,
            context: .init(methodPath: "blockchain.transaction.get_merkle")
        )

        #expect(result.merkle == [String(repeating: "a", count: 64), String(repeating: "b", count: 64)])
        #expect(result.blockHeight == 3)
        #expect(result.position == 1)
    }

    @Test("Rejects transaction merkle proofs with malformed branch hashes")
    func rejectTransactionMerkleProofsWithMalformedBranchHashes() throws {
        let proofPayload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "merkle": [String(repeating: "a", count: 63)],
                    "block_height": 3,
                    "pos": 1
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try proofPayload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.Merkle.self,
                context: .init(methodPath: "blockchain.transaction.get_merkle")
            )
        }

        let idFromPosPayload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "merkle": [String(repeating: "a", count: 63)],
                    "tx_hash": String(repeating: "f", count: 64)
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try idFromPosPayload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.IDFromPos.self,
                context: .init(methodPath: "blockchain.transaction.id_from_pos")
            )
        }
    }
}
