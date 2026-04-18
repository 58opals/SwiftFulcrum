// ResponseDecodingValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ResponseDecodingValidator {
    @Test("Classifies regular/subscription/error/empty envelopes")
    func classifyEnvelopes() throws {
        let identifier = UUID().uuidString

        let regularData = try jsonData(["jsonrpc": "2.0", "id": identifier, "result": "ok"])
        let regularEnvelope = try JSONDecoder().decode(SwiftFulcrum.RPC.Response.JSONRPC.Generic<String>.self, from: regularData)
        if case .regular(let regular) = try regularEnvelope.determineResponseType() {
            #expect(regular.result == "ok")
        } else {
            Issue.record("Expected regular response envelope")
        }

        let subscriptionData = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.headers.subscribe", "params": "update"]
        )
        let subscriptionEnvelope = try JSONDecoder().decode(SwiftFulcrum.RPC.Response.JSONRPC.Generic<String>.self, from: subscriptionData)
        if case .subscription(let subscription) = try subscriptionEnvelope.determineResponseType() {
            #expect(subscription.methodPath == "blockchain.headers.subscribe")
            #expect(subscription.result == "update")
        } else {
            Issue.record("Expected subscription response envelope")
        }

        let errorData = try jsonData(
            ["jsonrpc": "2.0", "id": identifier, "error": ["code": -1, "message": "boom"]]
        )
        let errorEnvelope = try JSONDecoder().decode(SwiftFulcrum.RPC.Response.JSONRPC.Generic<String>.self, from: errorData)
        if case .error(let rpcError) = try errorEnvelope.determineResponseType() {
            #expect(rpcError.error.code == -1)
            #expect(rpcError.error.message == "boom")
        } else {
            Issue.record("Expected error response envelope")
        }

        let emptyData = try jsonData(["jsonrpc": "2.0", "id": identifier])
        let emptyEnvelope = try JSONDecoder().decode(SwiftFulcrum.RPC.Response.JSONRPC.Generic<String?>.self, from: emptyData)
        if case .empty(let id) = try emptyEnvelope.determineResponseType() {
            #expect(id.uuidString == identifier)
        } else {
            Issue.record("Expected empty response envelope")
        }
    }

    @Test("Decodes server.version and server.features")
    func decodeServerMetadataResponses() throws {
        let versionPayload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": ["Fulcrum 2.0", "1.5.3"]]
        )
        let version = try versionPayload.decode(
            SwiftFulcrum.RPC.Response.Result.Server.Version.self,
            context: .init(methodPath: "server.version")
        )
        #expect(version.serverVersion == "Fulcrum 2.0")
        #expect(version.negotiatedProtocolVersion == SwiftFulcrum.ProtocolVersion(string: "1.5.3"))

        let featuresPayload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "genesis_hash": String(repeating: "0", count: 64),
                    "hash_function": "sha256",
                    "server_version": "Fulcrum 2.0",
                    "protocol_max": "1.6.0",
                    "protocol_min": "1.4.0",
                    "cashtokens": true,
                    "dsproof": true
                ]
            ]
        )
        let features = try featuresPayload.decode(
            SwiftFulcrum.RPC.Response.Result.Server.Features.self,
            context: .init(methodPath: "server.features")
        )
        #expect(features.maximumProtocolVersion == SwiftFulcrum.ProtocolVersion(string: "1.6.0"))
        #expect(features.minimumProtocolVersion == SwiftFulcrum.ProtocolVersion(string: "1.4.0"))
        #expect(features.hasCashTokens == true)
        #expect(features.hasDoubleSpendProofs == true)
    }

    @Test("Decodes nil result payloads without wrapper adapters")
    func decodeNilResultPayloads() throws {
        let pingPayload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        _ = try pingPayload.decode(
            SwiftFulcrum.RPC.Response.Result.Server.Ping.self,
            context: .init(methodPath: "server.ping")
        )

        let firstUsePayload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        let firstUse = try firstUsePayload.decode(
            SwiftFulcrum.RPC.Response.Result.Blockchain.Address.GetFirstUse.self,
            context: .init(methodPath: "blockchain.address.get_first_use")
        )
        #expect(firstUse.isFound == false)
        #expect(firstUse.blockHash == nil)
        #expect(firstUse.height == nil)
        #expect(firstUse.transactionHash == nil)

        let subscribePayload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        let subscribe = try subscribePayload.decode(
            SwiftFulcrum.RPC.Response.Result.Blockchain.Address.Subscribe.self,
            context: .init(methodPath: "blockchain.address.subscribe")
        )
        #expect(subscribe.status == nil)
    }

    @Test("Decodes headers/address/transaction/dsproof notifications")
    func decodeSubscriptionNotifications() throws {
        let headerPayload = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.headers.subscribe", "params": [["height": 1, "hex": String(repeating: "a", count: 160)]]]
        )
        let headerUpdate = try headerPayload.decode(
            SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.headers.subscribe")
        )
        #expect(headerUpdate.subscriptionIdentifier == "blockchain.headers.subscribe")
        #expect(headerUpdate.blocks.count == 1)

        let addressPayload = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.address.subscribe", "params": ["bitcoincash:qtest", "status"]]
        )
        let addressUpdate = try addressPayload.decode(
            SwiftFulcrum.RPC.Response.Result.Blockchain.Address.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.address.subscribe")
        )
        #expect(addressUpdate.subscriptionIdentifier == "bitcoincash:qtest")
        #expect(addressUpdate.status == "status")

        let transactionPayload = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.transaction.subscribe", "params": ["abc123", 42]]
        )
        let transactionUpdate = try transactionPayload.decode(
            SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.transaction.subscribe")
        )
        #expect(transactionUpdate.subscriptionIdentifier == "abc123")
        #expect(transactionUpdate.height == 42)

        let dsProofPayload = try jsonData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.transaction.dsproof.subscribe",
                "params": [
                    "abc123",
                    [
                        "dspid": "proof-id",
                        "txid": "abc123",
                        "hex": "00",
                        "outpoint": ["txid": "prev", "vout": 1],
                        "descendants": []
                    ]
                ]
            ]
        )
        let dsProofUpdate = try dsProofPayload.decode(
            SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.DSProof.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.transaction.dsproof.subscribe")
        )
        #expect(dsProofUpdate.subscriptionIdentifier == "abc123")
        #expect(dsProofUpdate.proof?.transactionID == "abc123")
    }

    @Test("Rejects oversized address and scripthash notification payloads")
    func rejectOversizedAddressAndScriptHashNotifications() throws {
        let addressPayload = try jsonData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.address.subscribe",
                "params": ["bitcoincash:qtest", "status", "unexpected"]
            ]
        )
        #expect(throws: ResponseResultDecodeError.self) {
            _ = try addressPayload.decode(
                SwiftFulcrum.RPC.Response.Result.Blockchain.Address.SubscribeNotification.self,
                context: .init(methodPath: "blockchain.address.subscribe")
            )
        }

        let scripthashPayload = try jsonData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.scripthash.subscribe",
                "params": [String(repeating: "b", count: 64), "status", "unexpected"]
            ]
        )
        #expect(throws: ResponseResultDecodeError.self) {
            _ = try scripthashPayload.decode(
                SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.SubscribeNotification.self,
                context: .init(methodPath: "blockchain.scripthash.subscribe")
            )
        }
    }

    @Test("Decodes mempool fee histogram flexible number pairs")
    func decodeMempoolFeeHistogram() throws {
        let payload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": [[2.5, 2000], [1, 1000]]]
        )
        let histogram = try payload.decode(
            SwiftFulcrum.RPC.Response.Result.Mempool.GetFeeHistogram.self,
            context: .init(methodPath: "mempool.get_fee_histogram")
        )
        #expect(histogram.histogram.count == 2)
        #expect(histogram.histogram[0].fee == 1.0)
        #expect(histogram.histogram[0].virtualSize == 1000)
        #expect(histogram.histogram[1].fee == 2.5)
        #expect(histogram.histogram[1].virtualSize == 2000)
    }

    @Test("Decodes verbose mempool transactions without confirmation metadata")
    func decodeVerboseMempoolTransactionWithoutConfirmationMetadata() throws {
        let payload = try jsonData(
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
            SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.Get.self,
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

    @Test("Decodes verbose coinbase transactions without spend-input fields")
    func decodeVerboseCoinbaseTransaction() throws {
        let payload = try jsonData(
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
            SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.Get.self,
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
        let payload = try jsonData(
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
            SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.Get.self,
            context: .init(methodPath: "blockchain.transaction.get")
        )

        #expect(transaction.outputs.count == 1)
        #expect(transaction.outputs[0].scriptPubKey.addresses == ["bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"])
    }

    @Test("Rejects malformed block.headers batches instead of truncating them")
    func rejectMalformedBlockHeaderBatch() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "count": 2,
                    "hex": String(repeating: "a", count: 161),
                    "max": 2016
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.RPC.Response.Result.Blockchain.Block.Headers.self,
                context: .init(methodPath: "blockchain.block.headers")
            )
        }
    }

    @Test("Rejects malformed block.headers arrays with invalid header widths")
    func rejectMalformedBlockHeaderArray() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "count": 1,
                    "headers": [String(repeating: "b", count: 159)],
                    "max": 2016
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.RPC.Response.Result.Blockchain.Block.Headers.self,
                context: .init(methodPath: "blockchain.block.headers")
            )
        }
    }

    @Test("Unexpected format errors include decode context")
    func enrichUnexpectedFormatWithContext() throws {
        let payload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": ["Fulcrum 2.0", "invalid"]]
        )

        do {
            _ = try payload.decode(
                SwiftFulcrum.RPC.Response.Result.Server.Version.self,
                context: .init(methodPath: "server.version")
            )
            Issue.record("Expected decode to fail with unexpected format")
        } catch let error as ResponseResultDecodeError {
            guard case .unexpectedFormat(let message) = error else {
                Issue.record("Expected unexpected format, got \(error)")
                return
            }
            #expect(message.contains("[method: server.version]"))
            #expect(message.contains("[payload: "))
        }
    }

    private func jsonData(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object)
    }
}
