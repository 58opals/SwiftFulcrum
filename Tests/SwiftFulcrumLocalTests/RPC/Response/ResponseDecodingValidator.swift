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

    @Test("Rejects non-JSON-RPC-2.0 envelopes")
    func rejectNonJSONRPC2Envelope() throws {
        let payload = try jsonData(["jsonrpc": "1.0", "id": UUID().uuidString, "result": "ok"])

        #expect(throws: DecodingError.self) {
            _ = try payload.decode(String.self, context: .init(methodPath: "server.banner"))
        }
    }

    @Test("Rejects non-JSON-RPC-2.0 identifier envelopes")
    func rejectNonJSONRPC2IdentifierEnvelope() throws {
        let payload = try jsonData(["jsonrpc": "1.0", "id": UUID().uuidString, "result": true])

        #expect(throws: DecodingError.self) {
            _ = try SwiftFulcrum.RPC.Response.JSONRPC.extractIdentifier(from: payload)
        }
    }

    @Test("Rejects non-JSON-RPC-2.0 erased envelopes")
    func rejectNonJSONRPC2ErasedEnvelope() throws {
        let payload = try jsonData(["jsonrpc": "1.0", "id": UUID().uuidString, "result": true])

        #expect(throws: DecodingError.self) {
            _ = try SwiftFulcrum.RPC.Response.JSONRPC.classifyErasedResponse(from: payload)
        }
    }

    @Test("Rejects envelopes that contain both result and error")
    func rejectEnvelopeWithResultAndError() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": "ok",
                "error": ["code": -1, "message": "boom"]
            ]
        )

        #expect(throws: JSONRPCResponseDecodeError.self) {
            _ = try payload.decode(String.self, context: .init(methodPath: "server.banner"))
        }
    }

    @Test("Rejects erased envelopes that contain both result and error")
    func rejectErasedEnvelopeWithResultAndError() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": true,
                "error": ["code": -1, "message": "boom"]
            ]
        )

        #expect(throws: JSONRPCResponseDecodeError.self) {
            _ = try SwiftFulcrum.RPC.Response.JSONRPC.classifyErasedResponse(from: payload)
        }
    }

    @Test("Rejects envelopes with null error members")
    func rejectEnvelopeWithNullError() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "error": NSNull()
            ]
        )

        #expect(throws: JSONRPCResponseDecodeError.self) {
            _ = try payload.decode(String.self, context: .init(methodPath: "server.banner"))
        }
    }

    @Test("Rejects erased envelopes with null error members")
    func rejectErasedEnvelopeWithNullError() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "error": NSNull()
            ]
        )

        #expect(throws: JSONRPCResponseDecodeError.self) {
            _ = try SwiftFulcrum.RPC.Response.JSONRPC.classifyErasedResponse(from: payload)
        }
    }

    @Test("Rejects subscription envelopes that contain an error")
    func rejectSubscriptionEnvelopeWithError() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.headers.subscribe",
                "params": "update",
                "error": ["code": -1, "message": "boom"]
            ]
        )

        #expect(throws: JSONRPCResponseDecodeError.self) {
            _ = try payload.decode(String.self, context: .init(methodPath: "blockchain.headers.subscribe"))
        }
    }

    @Test("Rejects erased setup responses that contain subscription fields")
    func rejectErasedSetupResponseWithSubscriptionFields() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": "status",
                "method": "blockchain.headers.subscribe",
                "params": "update"
            ]
        )

        #expect(throws: JSONRPCResponseDecodeError.self) {
            _ = try SwiftFulcrum.RPC.Response.JSONRPC.classifyErasedResponse(from: payload)
        }
    }

    @Test("Decodes server.version and server.features")
    func decodeServerMetadataResponses() throws {
        let versionPayload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": ["Fulcrum 2.0", "1.5.3"]]
        )
        let version = try versionPayload.decode(
            SwiftFulcrum.Response.Server.Version.self,
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
            SwiftFulcrum.Response.Server.Features.self,
            context: .init(methodPath: "server.features")
        )
        #expect(features.maximumProtocolVersion == SwiftFulcrum.ProtocolVersion(string: "1.6.0"))
        #expect(features.minimumProtocolVersion == SwiftFulcrum.ProtocolVersion(string: "1.4.0"))
        #expect(features.hasCashTokens == true)
        #expect(features.hasDoubleSpendProofs == true)
    }

    @Test("Rejects server.features with an inverted protocol range")
    func rejectServerFeaturesWithInvertedProtocolRange() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "genesis_hash": String(repeating: "0", count: 64),
                    "hash_function": "sha256",
                    "server_version": "Fulcrum 2.0",
                    "protocol_max": "1.4.0",
                    "protocol_min": "1.6.0"
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Server.Features.self,
                context: .init(methodPath: "server.features")
            )
        }
    }

    @Test("Rejects server.features host ports outside the valid range")
    func rejectServerFeaturesHostPortsOutsideValidRange() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "genesis_hash": String(repeating: "0", count: 64),
                    "hash_function": "sha256",
                    "server_version": "Fulcrum 2.0",
                    "protocol_max": "1.6.0",
                    "protocol_min": "1.4.0",
                    "hosts": [
                        "invalid.fulcrum.example": ["wss_port": 0]
                    ]
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Server.Features.self,
                context: .init(methodPath: "server.features")
            )
        }
    }

    @Test("Rejects server.features reusable payment address negative values")
    func rejectServerFeaturesReusablePaymentAddressNegativeValues() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "genesis_hash": String(repeating: "0", count: 64),
                    "hash_function": "sha256",
                    "server_version": "Fulcrum 2.0",
                    "protocol_max": "1.6.0",
                    "protocol_min": "1.4.0",
                    "rpa": [
                        "history_block_limit": -1,
                        "max_history": 100,
                        "prefix_bits": 20,
                        "prefix_bits_min": 8,
                        "starting_height": 0
                    ]
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Server.Features.self,
                context: .init(methodPath: "server.features")
            )
        }
    }

    @Test("Rejects server.version arrays with extra fields")
    func rejectServerVersionArraysWithExtraFields() throws {
        let payload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": ["Fulcrum 2.0", "1.5.3", "extra"]]
        )

        #expect(throws: DecodingError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Server.Version.self,
                context: .init(methodPath: "server.version")
            )
        }
    }

    @Test("Decodes nil result payloads without wrapper adapters")
    func decodeNilResultPayloads() throws {
        let pingPayload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        _ = try pingPayload.decode(
            SwiftFulcrum.Response.Server.Ping.self,
            context: .init(methodPath: "server.ping")
        )

        let firstUsePayload = try jsonData(
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

        let subscribePayload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        let subscribe = try subscribePayload.decode(
            SwiftFulcrum.Response.Blockchain.Address.Subscribe.self,
            context: .init(methodPath: "blockchain.address.subscribe")
        )
        #expect(subscribe.status == nil)
    }

    @Test("Rejects negative blockchain relay fees")
    func rejectNegativeBlockchainRelayFee() throws {
        let payload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": -0.00001]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.RelayFee.self,
                context: .init(methodPath: "blockchain.relayfee")
            )
        }
    }

    @Test("Decodes unknown transaction height status")
    func decodeUnknownTransactionHeightStatus() throws {
        let getHeightPayload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        let getHeight = try getHeightPayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.Height.self,
            context: .init(methodPath: "blockchain.transaction.get_height")
        )
        #expect(getHeight.height == nil)

        let subscribePayload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        let subscribe = try subscribePayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.Subscribe.self,
            context: .init(methodPath: "blockchain.transaction.subscribe")
        )
        #expect(subscribe.height == nil)

        let notificationPayload = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.transaction.subscribe", "params": ["abc123", NSNull()]]
        )
        let notification = try notificationPayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.transaction.subscribe")
        )
        #expect(notification.transactionHash == "abc123")
        #expect(notification.height == nil)
    }

    @Test("Rejects reversed transaction subscribe notification payloads")
    func rejectReversedTransactionSubscribeNotificationPayload() throws {
        let payload = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.transaction.subscribe", "params": [42, "abc123"]]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.SubscribeNotification.self,
                context: .init(methodPath: "blockchain.transaction.subscribe")
            )
        }
    }

    @Test("Decodes missing UTXO info as not found")
    func decodeMissingUTXOInfoAsNotFound() throws {
        let payload = try jsonData(
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

    @Test("Decodes blockchain header lookup")
    func decodeBlockchainHeaderLookup() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "height": 1,
                    "hex": String(repeating: "a", count: 160)
                ]
            ]
        )

        let header = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Header.Lookup.self,
            context: .init(methodPath: "blockchain.header.get")
        )

        #expect(header.height == 1)
        #expect(header.hex == String(repeating: "a", count: 160))
    }

    @Test("Rejects malformed blockchain header lookups with invalid header widths")
    func rejectMalformedBlockchainHeaderLookupWithInvalidHeaderWidth() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "height": 1,
                    "hex": String(repeating: "a", count: 158)
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Header.Lookup.self,
                context: .init(methodPath: "blockchain.header.get")
            )
        }
    }

    @Test("Decodes blockchain headers tip")
    func decodeBlockchainHeadersTip() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "height": 2,
                    "hex": String(repeating: "b", count: 160)
                ]
            ]
        )

        let tip = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
            context: .init(methodPath: "blockchain.headers.get_tip")
        )

        #expect(tip.height == 2)
        #expect(tip.hex == String(repeating: "b", count: 160))
    }

    @Test("Rejects malformed blockchain headers tips with invalid header widths")
    func rejectMalformedBlockchainHeadersTipWithInvalidHeaderWidth() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "height": 2,
                    "hex": String(repeating: "b", count: 158)
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
                context: .init(methodPath: "blockchain.headers.get_tip")
            )
        }
    }

    @Test("Decodes missing double-spend proof as not found")
    func decodeMissingDSProofAsNotFound() throws {
        let getPayload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        let get = try getPayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Lookup.self,
            context: .init(methodPath: "blockchain.transaction.dsproof.get")
        )
        #expect(get.isFound == false)
        #expect(get.dsProofID == nil)
        #expect(get.transactionID == nil)
        #expect(get.hex == nil)
        #expect(get.outpoint == nil)
        #expect(get.descendants.isEmpty)

        let subscribePayload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        let subscribe = try subscribePayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Subscribe.self,
            context: .init(methodPath: "blockchain.transaction.dsproof.subscribe")
        )
        #expect(subscribe.proof == nil)

        let notificationPayload = try jsonData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.transaction.dsproof.subscribe",
                "params": ["abc123", NSNull()]
            ]
        )
        let notification = try notificationPayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.DSProof.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.transaction.dsproof.subscribe")
        )
        #expect(notification.transactionHash == "abc123")
        #expect(notification.proof == nil)
    }

    @Test("Rejects reversed DSProof subscribe notification payloads")
    func rejectReversedDSProofSubscribeNotificationPayload() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.transaction.dsproof.subscribe",
                "params": [
                    [
                        "dspid": "proof-id",
                        "txid": "abc123",
                        "hex": "00",
                        "outpoint": ["txid": "prev", "vout": 1],
                        "descendants": []
                    ],
                    "abc123"
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.DSProof.SubscribeNotification.self,
                context: .init(methodPath: "blockchain.transaction.dsproof.subscribe")
            )
        }
    }

    @Test("Decodes routeable DSProof notification proof-only payloads")
    func decodeRouteableDSProofNotificationProofOnlyPayload() throws {
        let proof: [String: Any] = [
            "dspid": "proof-id",
            "txid": "abc123",
            "hex": "00",
            "outpoint": ["txid": "prev", "vout": 1],
            "descendants": []
        ]
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.transaction.dsproof.subscribe",
                "params": [proof]
            ]
        )

        #expect(
            FulcrumNetworkClient.makeSubscriptionIdentifier(
                methodPath: "blockchain.transaction.dsproof.subscribe",
                data: payload
            ) == "abc123"
        )

        let notification = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.DSProof.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.transaction.dsproof.subscribe")
        )
        #expect(notification.subscriptionIdentifier == "abc123")
        #expect(notification.transactionHash == "abc123")
        #expect(notification.proof?.transactionID == "abc123")
    }

    @Test("Decodes headers/address/transaction/dsproof notifications")
    func decodeSubscriptionNotifications() throws {
        let headerPayload = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.headers.subscribe", "params": [["height": 1, "hex": String(repeating: "a", count: 160)]]]
        )
        let headerUpdate = try headerPayload.decode(
            SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.headers.subscribe")
        )
        #expect(headerUpdate.subscriptionIdentifier == "blockchain.headers.subscribe")
        #expect(headerUpdate.blocks.count == 1)

        let addressPayload = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.address.subscribe", "params": ["bitcoincash:qtest", "status"]]
        )
        let addressUpdate = try addressPayload.decode(
            SwiftFulcrum.Response.Blockchain.Address.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.address.subscribe")
        )
        #expect(addressUpdate.subscriptionIdentifier == "bitcoincash:qtest")
        #expect(addressUpdate.status == "status")

        let transactionPayload = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.transaction.subscribe", "params": ["abc123", 42]]
        )
        let transactionUpdate = try transactionPayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.SubscribeNotification.self,
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
            SwiftFulcrum.Response.Blockchain.Transaction.DSProof.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.transaction.dsproof.subscribe")
        )
        #expect(dsProofUpdate.subscriptionIdentifier == "abc123")
        #expect(dsProofUpdate.proof?.transactionID == "abc123")
    }

    @Test("Dropping a decoded stream fires the decode termination hook")
    func droppingDecodedStreamFiresTerminationHook() async throws {
        let terminationState = TerminationState()
        let rawStream = AsyncThrowingStream<Data, Swift.Error> { _ in }
        var decodedStream: AsyncThrowingStream<String, Swift.Error>? = rawStream.decode(
            String.self,
            onTermination: {
                Task {
                    await terminationState.markTerminated()
                }
            }
        )
        #expect(decodedStream != nil)

        decodedStream = nil

        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(1))
        while clock.now < deadline {
            if await terminationState.isTerminated {
                return
            }
            try await Task.sleep(for: .milliseconds(10))
        }

        Issue.record("Expected the decode termination hook after dropping the decoded stream")
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
                SwiftFulcrum.Response.Blockchain.Address.SubscribeNotification.self,
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
                SwiftFulcrum.Response.Blockchain.ScriptHash.SubscribeNotification.self,
                context: .init(methodPath: "blockchain.scripthash.subscribe")
            )
        }
    }

    @Test("Rejects undersized address and scripthash notification payloads")
    func rejectUndersizedAddressAndScriptHashNotifications() throws {
        let addressPayload = try jsonData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.address.subscribe",
                "params": ["bitcoincash:qtest"]
            ]
        )
        #expect(throws: ResponseResultDecodeError.self) {
            _ = try addressPayload.decode(
                SwiftFulcrum.Response.Blockchain.Address.SubscribeNotification.self,
                context: .init(methodPath: "blockchain.address.subscribe")
            )
        }

        let scripthashPayload = try jsonData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.scripthash.subscribe",
                "params": [String(repeating: "b", count: 64)]
            ]
        )
        #expect(throws: ResponseResultDecodeError.self) {
            _ = try scripthashPayload.decode(
                SwiftFulcrum.Response.Blockchain.ScriptHash.SubscribeNotification.self,
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
            SwiftFulcrum.Response.Mempool.FeeHistogram.self,
            context: .init(methodPath: "mempool.get_fee_histogram")
        )
        #expect(histogram.histogram.count == 2)
        #expect(histogram.histogram[0].fee == 2.5)
        #expect(histogram.histogram[0].virtualSize == 2000)
        #expect(histogram.histogram[1].fee == 1.0)
        #expect(histogram.histogram[1].virtualSize == 1000)
    }

    @Test("Rejects invalid mempool info fee values")
    func rejectInvalidMempoolInfoFeeValues() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "mempoolminfee": "nan",
                    "minrelaytxfee": -1,
                    "incrementalrelayfee": "inf"
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Mempool.Info.self,
                context: .init(methodPath: "mempool.get_info")
            )
        }
    }

    @Test("Rejects negative mempool info unbroadcast count")
    func rejectNegativeMempoolInfoUnbroadcastCount() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "unbroadcastcount": -1
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Mempool.Info.self,
                context: .init(methodPath: "mempool.get_info")
            )
        }
    }

    @Test("Rejects oversized mempool fee histogram virtual sizes")
    func rejectOversizedMempoolFeeHistogramVirtualSize() throws {
        let payload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": [[1, "18446744073709551616"]]]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Mempool.FeeHistogram.self,
                context: .init(methodPath: "mempool.get_fee_histogram")
            )
        }
    }

    @Test("Rejects fractional mempool fee histogram virtual sizes")
    func rejectFractionalMempoolFeeHistogramVirtualSize() throws {
        let payload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": [[1, 2000.75]]]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Mempool.FeeHistogram.self,
                context: .init(methodPath: "mempool.get_fee_histogram")
            )
        }
    }

    @Test("Decodes transaction.id_from_pos without a merkle proof")
    func decodeTransactionIDFromPosWithoutMerkleProof() throws {
        let transactionHash = String(repeating: "f", count: 64)
        let payload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": transactionHash]
        )

        let result = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.IDFromPos.self,
            context: .init(methodPath: "blockchain.transaction.id_from_pos")
        )

        #expect(result.transactionHash == transactionHash)
        #expect(result.merkle.isEmpty)
    }

    @Test("Decodes transaction merkle proof")
    func decodeTransactionMerkleProof() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "merkle": ["a", "b"],
                    "block_height": 3,
                    "pos": 1
                ]
            ]
        )

        let result = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.Merkle.self,
            context: .init(methodPath: "blockchain.transaction.get_merkle")
        )

        #expect(result.merkle == ["a", "b"])
        #expect(result.blockHeight == 3)
        #expect(result.position == 1)
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
            SwiftFulcrum.Response.Blockchain.Transaction.Verbose.self,
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
                SwiftFulcrum.Response.Blockchain.Block.Headers.self,
                context: .init(methodPath: "blockchain.block.headers")
            )
        }
    }

    @Test("Rejects block.headers counts larger than Int.max")
    func rejectBlockHeaderCountLargerThanIntMax() throws {
        let payload = Data(
            """
            {
                "jsonrpc": "2.0",
                "id": "\(UUID().uuidString)",
                "result": {
                    "count": 9223372036854775808,
                    "hex": "",
                    "max": 2016
                }
            }
            """.utf8
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Block.Headers.self,
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
                SwiftFulcrum.Response.Blockchain.Block.Headers.self,
                context: .init(methodPath: "blockchain.block.headers")
            )
        }
    }

    @Test("Rejects malformed block.header payloads with invalid header widths")
    func rejectMalformedBlockHeaderWithInvalidHeaderWidth() throws {
        let payload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": String(repeating: "a", count: 158)]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Block.Header.self,
                context: .init(methodPath: "blockchain.block.header")
            )
        }
    }

    @Test("Rejects incomplete block.headers proof metadata")
    func rejectIncompleteBlockHeaderProofMetadata() throws {
        let payload = try jsonData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "count": 1,
                    "hex": String(repeating: "c", count: 160),
                    "max": 2016,
                    "branch": [String(repeating: "d", count: 64)]
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Block.Headers.self,
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
                SwiftFulcrum.Response.Server.Version.self,
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
