// ResponseDecodingValidator~RPA.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Decodes every RPA history field and preserves response order")
    func decodeRPAHistory() throws {
        let firstHash =
            "acc3758bd2a26f869fcc67d48ff30b96464d476bca82c1cd6656e7d506816412"
        let secondHash =
            "f3e1bf48975b8d6060a9de8884296abb80be618dc00ae3cb2f6cee3085e09403"
        let payload = try makeRPAResponsePayload([
            ["height": 825_000, "tx_hash": firstHash],
            ["height": 825_008, "tx_hash": secondHash]
        ])

        let history = try payload.decode(
            SwiftFulcrum.Response.Blockchain.RPA.History.self,
            context: .init(methodPath: "blockchain.rpa.get_history")
        )

        #expect(history.transactions.map(\.height) == [825_000, 825_008])
        #expect(
            history.transactions.map(\.transactionHash)
                == [firstHash, secondHash]
        )
    }

    @Test("Decodes every RPA mempool field with documented height semantics")
    func decodeRPAMempool() throws {
        let confirmedParentsHash =
            "354a24a255488c28c9cdfe7134d1b86bb99bbcca2bc7996b9613990bed384cc8"
        let unconfirmedParentHash =
            "45381031132c57b2ff1cbe8d8d3920cf9ed25efd9a0beb764bdb2f24c7d1c7e3"
        let payload = try makeRPAResponsePayload([
            [
                "height": 0,
                "tx_hash": confirmedParentsHash,
                "fee": 24_310
            ],
            [
                "height": -1,
                "tx_hash": unconfirmedParentHash,
                "fee": 185
            ]
        ])

        let mempool = try payload.decode(
            SwiftFulcrum.Response.Blockchain.RPA.Mempool.self,
            context: .init(methodPath: "blockchain.rpa.get_mempool")
        )

        #expect(mempool.transactions.map(\.height) == [0, -1])
        #expect(
            mempool.transactions.map(\.transactionHash)
                == [confirmedParentsHash, unconfirmedParentHash]
        )
        #expect(mempool.transactions.map(\.fee) == [24_310, 185])
    }

    @Test("Rejects negative confirmed RPA history heights")
    func rejectNegativeRPAHistoryHeight() throws {
        let payload = try makeRPAResponsePayload([
            [
                "height": -1,
                "tx_hash": String(repeating: "a", count: 64)
            ]
        ])

        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Blockchain.RPA.History.self,
            from: payload,
            methodPath: "blockchain.rpa.get_history"
        )
    }

    @Test("Rejects malformed RPA history transaction hashes")
    func rejectMalformedRPAHistoryTransactionHash() throws {
        let payload = try makeRPAResponsePayload([
            [
                "height": 825_000,
                "tx_hash": String(repeating: "g", count: 64)
            ]
        ])

        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Blockchain.RPA.History.self,
            from: payload,
            methodPath: "blockchain.rpa.get_history"
        )
    }

    @Test(
        "Rejects undocumented RPA mempool heights",
        arguments: [-2, 1]
    )
    func rejectUndocumentedRPAMempoolHeight(_ height: Int) throws {
        let payload = try makeRPAResponsePayload([
            [
                "height": height,
                "tx_hash": String(repeating: "a", count: 64),
                "fee": 1
            ]
        ])

        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Blockchain.RPA.Mempool.self,
            from: payload,
            methodPath: "blockchain.rpa.get_mempool"
        )
    }

    @Test("Rejects RPA mempool records without fees")
    func rejectRPAMempoolRecordWithoutFee() throws {
        let payload = try makeRPAResponsePayload([
            [
                "height": 0,
                "tx_hash": String(repeating: "a", count: 64)
            ]
        ])

        #expect(throws: DecodingError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.RPA.Mempool.self,
                context: .init(methodPath: "blockchain.rpa.get_mempool")
            )
        }
    }

    @Test("Rejects negative RPA mempool fees")
    func rejectNegativeRPAMempoolFee() throws {
        let payload = try makeRPAResponsePayload([
            [
                "height": 0,
                "tx_hash": String(repeating: "a", count: 64),
                "fee": -1
            ]
        ])

        #expect(throws: DecodingError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.RPA.Mempool.self,
                context: .init(methodPath: "blockchain.rpa.get_mempool")
            )
        }
    }

    @Test("Rejects malformed RPA mempool transaction hashes")
    func rejectMalformedRPAMempoolTransactionHash() throws {
        let payload = try makeRPAResponsePayload([
            [
                "height": 0,
                "tx_hash": String(repeating: "a", count: 63),
                "fee": 1
            ]
        ])

        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Blockchain.RPA.Mempool.self,
            from: payload,
            methodPath: "blockchain.rpa.get_mempool"
        )
    }

    private func makeRPAResponsePayload(_ result: [[String: Any]]) throws -> Data {
        try makeJSONData([
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "result": result
        ])
    }
}
