// ResponseDecodingValidator~VerboseTransactionOutput.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Decodes verbose coinbase transactions without spend-input fields")
    func decodeVerboseCoinbaseTransaction() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "blockhash": String(repeating: "0", count: 64),
                    "blocktime": 1_520_074_861,
                    "confirmations": 679,
                    "hash": "4f0b8f66c9f4f4f833e8ef7d8e731654c5e7f4a90b1f8be7508f3a6a7bb9c001",
                    "hex": "02000000",
                    "locktime": 0,
                    "size": 204,
                    "time": 1_520_074_861,
                    "txid": "4f0b8f66c9f4f4f833e8ef7d8e731654c5e7f4a90b1f8be7508f3a6a7bb9c001",
                    "version": 2,
                    "vin": [
                        [
                            "coinbase": "03aabbcc",
                            "sequence": 4_294_967_295
                        ]
                    ],
                    "vout": [
                        [
                            "n": 0,
                            "scriptPubKey": [
                                "asm": "OP_HASH160 deadbeef OP_EQUAL",
                                "hex": "a914deadbeef87",
                                "type": "scripthash"
                            ],
                            "value": 6.25
                        ]
                    ]
                ]
            ]
        )

        let transaction = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.Verbose.self,
            context: .init(methodPath: "blockchain.transaction.get")
        )

        #expect(transaction.inputs.count == 1)
        #expect(transaction.inputs[0].isCoinbase)
        #expect(transaction.inputs[0].coinbase == "03aabbcc")
        #expect(transaction.inputs[0].scriptSig == nil)
        #expect(transaction.inputs[0].transactionID == nil)
        #expect(transaction.inputs[0].indexNumberOfPreviousTransactionOutput == nil)
    }

    @Test("Decodes verbose transaction outputs that use singular scriptPubKey address")
    func decodeVerboseTransactionOutputWithSingularAddress() throws {
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
                                "address": "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a",
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

        #expect(transaction.outputs.count == 1)
        #expect(transaction.outputs[0].scriptPubKey.addresses == ["bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"])
    }
}
