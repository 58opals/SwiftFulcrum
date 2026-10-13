// ResponseDecodingValidator~TransactionBroadcast.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test(
        "Rejects signed byte chunks in transaction broadcast hashes",
        arguments: ["+1", "-0"], [0, 15, 31]
    )
    func rejectSignedTransactionBroadcastHashChunks(
        signedChunk: String,
        byteIndex: Int
    ) throws {
        let transactionHash = String(repeating: "ab", count: byteIndex)
            + signedChunk
            + String(repeating: "ab", count: 31 - byteIndex)
        let payload = try makeJSONData([
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "result": transactionHash
        ])

        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Blockchain.Transaction.Broadcast.self,
            from: payload,
            methodPath: "blockchain.transaction.broadcast"
        )
    }

    @Test(
        "Preserves exact transaction broadcast hash bytes for either hex case",
        arguments: [false, true]
    )
    func decodeTransactionBroadcastHashPreservesExactBytes(uppercase: Bool) throws {
        let lowercaseHash = "0123456789abcdef00112233445566778899aabbccddeefffedcba9876543210"
        let transactionHash = uppercase ? lowercaseHash.uppercased() : lowercaseHash
        let payload = try makeJSONData([
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "result": transactionHash
        ])
        let result = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.Broadcast.self,
            context: .init(methodPath: "blockchain.transaction.broadcast")
        )

        #expect(result.transactionHash == Data([
            0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef,
            0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
            0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff,
            0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10
        ]))
    }
}
