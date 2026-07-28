// ResponseDecodingValidator~History.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Rejects history entries with malformed transaction hashes")
    func rejectHistoryEntriesWithMalformedTransactionHashes() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    [
                        "height": 1,
                        "tx_hash": String(repeating: "a", count: 63)
                    ]
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Address.History.self,
                context: .init(methodPath: "blockchain.address.get_history")
            )
        }

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.ScriptHash.History.self,
                context: .init(methodPath: "blockchain.scripthash.get_history")
            )
        }
    }

    @Test(
        "Rejects history transactions with heights below negative one",
        arguments: [
            ("blockchain.address.get_history", true),
            ("blockchain.scripthash.get_history", false)
        ]
    )
    func rejectHistoryTransactionsWithHeightsBelowNegativeOne(
        methodPath: String,
        isAddressHistoryResponse: Bool
    ) throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    [
                        "height": -2,
                        "tx_hash": String(repeating: "a", count: 64)
                    ]
                ]
            ]
        )

        if isAddressHistoryResponse {
            expectResponseResultDecodeFailure(
                SwiftFulcrum.Response.Blockchain.Address.History.self,
                from: payload,
                methodPath: methodPath
            )
        } else {
            expectResponseResultDecodeFailure(
                SwiftFulcrum.Response.Blockchain.ScriptHash.History.self,
                from: payload,
                methodPath: methodPath
            )
        }
    }

    @Test(
        "Accepts documented unconfirmed history heights",
        arguments: [
            (-1, "blockchain.address.get_history", true),
            (0, "blockchain.address.get_history", true),
            (-1, "blockchain.scripthash.get_history", false),
            (0, "blockchain.scripthash.get_history", false)
        ]
    )
    func acceptDocumentedUnconfirmedHistoryHeight(
        height: Int,
        methodPath: String,
        isAddressHistoryResponse: Bool
    ) throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    [
                        "height": height,
                        "tx_hash": String(repeating: "a", count: 64)
                    ]
                ]
            ]
        )

        if isAddressHistoryResponse {
            let history = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Address.History.self,
                context: .init(methodPath: methodPath)
            )
            #expect(history.transactions.first?.height == height)
        } else {
            let history = try payload.decode(
                SwiftFulcrum.Response.Blockchain.ScriptHash.History.self,
                context: .init(methodPath: methodPath)
            )
            #expect(history.transactions.first?.height == height)
        }
    }
}
