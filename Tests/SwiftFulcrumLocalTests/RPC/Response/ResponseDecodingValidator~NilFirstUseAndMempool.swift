// ResponseDecodingValidator~NilFirstUseAndMempool.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Decodes nil result payloads without wrapper adapters")
    func decodeNilResultPayloads() throws {
        let pingPayload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        _ = try pingPayload.decode(
            SwiftFulcrum.Response.Server.Ping.self,
            context: .init(methodPath: "server.ping")
        )

        let firstUsePayload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        let firstUse = try firstUsePayload.decode(
            SwiftFulcrum.Response.Blockchain.Address.FirstUse.self,
            context: .init(methodPath: "blockchain.address.get_first_use")
        )
        #expect(firstUse.isFound == false)
        #expect(firstUse.blockHash == nil)
        #expect(firstUse.height == nil)
        #expect(firstUse.transactionHash == nil)

        let subscribePayload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        let subscribe = try subscribePayload.decode(
            SwiftFulcrum.Response.Blockchain.Address.Subscribe.self,
            context: .init(methodPath: "blockchain.address.subscribe")
        )
        #expect(subscribe.status == nil)
    }

    @Test("Rejects address first-use responses with malformed hashes")
    func rejectAddressFirstUseResponsesWithMalformedHashes() throws {
        try expectFirstUseResponseDecodeFailure(
            SwiftFulcrum.Response.Blockchain.Address.FirstUse.self,
            methodPath: "blockchain.address.get_first_use"
        )
    }

    @Test("Rejects scripthash first-use responses with malformed hashes")
    func rejectScriptHashFirstUseResponsesWithMalformedHashes() throws {
        try expectFirstUseResponseDecodeFailure(
            SwiftFulcrum.Response.Blockchain.ScriptHash.FirstUse.self,
            methodPath: "blockchain.scripthash.get_first_use"
        )
    }

    private func expectFirstUseResponseDecodeFailure<DecodedResponse: Decodable & Sendable>(
        _ responseType: DecodedResponse.Type,
        methodPath: String
    ) throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "block_hash": String(repeating: "a", count: 63),
                    "height": 1,
                    "tx_hash": String(repeating: "b", count: 64)
                ]
            ]
        )

        expectResponseResultDecodeFailure(responseType, from: payload, methodPath: methodPath)
    }

    @Test(
        "Rejects mempool transactions with malformed hashes",
        arguments: [
            ("blockchain.address.get_mempool", true),
            ("blockchain.scripthash.get_mempool", false)
        ]
    )
    func rejectMempoolTransactionsWithMalformedHashes(methodPath: String, isAddressMempoolResponse: Bool) throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    [
                        "height": 0,
                        "tx_hash": "abc123",
                        "fee": 1
                    ]
                ]
            ]
        )

        expectMempoolResponseDecodeFailure(
            from: payload,
            methodPath: methodPath,
            isAddressMempoolResponse: isAddressMempoolResponse
        )
    }

    @Test(
        "Rejects mempool transactions with invalid heights",
        arguments: [
            ("blockchain.address.get_mempool", true, -2),
            ("blockchain.address.get_mempool", true, 1),
            ("blockchain.scripthash.get_mempool", false, -2),
            ("blockchain.scripthash.get_mempool", false, 1)
        ]
    )
    func rejectMempoolTransactionsWithInvalidHeights(
        methodPath: String,
        isAddressMempoolResponse: Bool,
        height: Int
    ) throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    [
                        "height": height,
                        "tx_hash": String(repeating: "b", count: 64),
                        "fee": 1
                    ]
                ]
            ]
        )

        expectMempoolResponseDecodeFailure(
            from: payload,
            methodPath: methodPath,
            isAddressMempoolResponse: isAddressMempoolResponse
        )
    }

    private func expectMempoolResponseDecodeFailure(
        from payload: Data,
        methodPath: String,
        isAddressMempoolResponse: Bool
    ) {
        if isAddressMempoolResponse {
            expectResponseResultDecodeFailure(
                SwiftFulcrum.Response.Blockchain.Address.Mempool.self,
                from: payload,
                methodPath: methodPath
            )
        } else {
            expectResponseResultDecodeFailure(
                SwiftFulcrum.Response.Blockchain.ScriptHash.Mempool.self,
                from: payload,
                methodPath: methodPath
            )
        }
    }
}
