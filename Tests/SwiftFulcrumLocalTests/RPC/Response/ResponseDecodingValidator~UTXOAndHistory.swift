// ResponseDecodingValidator~UTXOAndHistory.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Decodes missing UTXO info as not found")
    func decodeMissingUTXOInfoAsNotFound() throws {
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )

        let result = try payload.decode(
            SwiftFulcrum.Response.Blockchain.UTXO.Info.self,
            context: .init(methodPath: "blockchain.utxo.get_info")
        )

        #expect(result.isFound == false)
        #expect(result.confirmedHeight == nil)
        #expect(result.scriptHash == nil)
        #expect(result.value == nil)
        #expect(result.tokenData == nil)
    }

    @Test("Rejects UTXO info responses with malformed script hashes")
    func rejectUTXOInfoResponsesWithMalformedScriptHashes() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "confirmed_height": 1,
                    "scripthash": "abc123",
                    "value": 546
                ]
            ]
        )

        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Blockchain.UTXO.Info.self,
            from: payload,
            methodPath: "blockchain.utxo.get_info"
        )
    }

    @Test("Rejects address.get_scripthash responses with malformed script hashes")
    func rejectAddressScriptHashResponsesWithMalformedScriptHashes() throws {
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": String(repeating: "g", count: 64)]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Address.ScriptHash.self,
                context: .init(methodPath: "blockchain.address.get_scripthash")
            )
        }
    }

    @Test("Rejects listunspent entries with malformed transaction hashes")
    func rejectListUnspentEntriesWithMalformedTransactionHashes() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    [
                        "height": 1,
                        "tx_hash": String(repeating: "a", count: 63),
                        "tx_pos": 0,
                        "value": 1000
                    ]
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Address.ListUnspent.self,
                context: .init(methodPath: "blockchain.address.listunspent")
            )
        }

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.ScriptHash.ListUnspent.self,
                context: .init(methodPath: "blockchain.scripthash.listunspent")
            )
        }
    }

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
}
