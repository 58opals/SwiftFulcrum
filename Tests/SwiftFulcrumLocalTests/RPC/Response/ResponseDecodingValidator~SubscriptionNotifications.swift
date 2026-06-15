// ResponseDecodingValidator~SubscriptionNotifications.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Decodes headers/address/transaction/dsproof notifications")
    func decodeSubscriptionNotifications() throws {
        let headerPayload = try makeJSONData(
            ["jsonrpc": "2.0", "method": "blockchain.headers.subscribe", "params": [["height": 1, "hex": String(repeating: "a", count: 160)]]]
        )
        let headerUpdate = try headerPayload.decode(
            SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.headers.subscribe")
        )
        #expect(headerUpdate.subscriptionIdentifier == "blockchain.headers.subscribe")
        #expect(headerUpdate.blocks.count == 1)

        let addressPayload = try makeJSONData(
            ["jsonrpc": "2.0", "method": "blockchain.address.subscribe", "params": ["bitcoincash:qtest", "status"]]
        )
        let addressUpdate = try addressPayload.decode(
            SwiftFulcrum.Response.Blockchain.Address.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.address.subscribe")
        )
        #expect(addressUpdate.subscriptionIdentifier == "bitcoincash:qtest")
        #expect(addressUpdate.status == "status")

        let transactionHash = String(repeating: "c", count: 64)
        let transactionPayload = try makeJSONData(
            ["jsonrpc": "2.0", "method": "blockchain.transaction.subscribe", "params": [transactionHash, 42]]
        )
        let transactionUpdate = try transactionPayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.transaction.subscribe")
        )
        #expect(transactionUpdate.subscriptionIdentifier == transactionHash)
        #expect(transactionUpdate.height == 42)

        let dsProofTransactionHash = String(repeating: "d", count: 64)
        let dsProofPayload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.transaction.dsproof.subscribe",
                "params": [
                    dsProofTransactionHash,
                    makeDSProofResult(transactionHash: dsProofTransactionHash)
                ]
            ]
        )
        let dsProofUpdate = try dsProofPayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.DSProof.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.transaction.dsproof.subscribe")
        )
        #expect(dsProofUpdate.subscriptionIdentifier == dsProofTransactionHash)
        #expect(dsProofUpdate.proof?.transactionID == dsProofTransactionHash)
    }

    @Test("Rejects malformed headers subscription notifications with invalid header widths")
    func rejectMalformedHeadersSubscriptionNotificationWithInvalidHeaderWidth() throws {
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "method": "blockchain.headers.subscribe", "params": [["height": 1, "hex": String(repeating: "a", count: 158)]]]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self,
                context: .init(methodPath: "blockchain.headers.subscribe")
            )
        }
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
        let addressPayload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.address.subscribe",
                "params": ["bitcoincash:qtest", "status", "unexpected"]
            ]
        )
        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Blockchain.Address.SubscribeNotification.self,
            from: addressPayload,
            methodPath: "blockchain.address.subscribe"
        )

        let scripthashPayload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.scripthash.subscribe",
                "params": [String(repeating: "b", count: 64), "status", "unexpected"]
            ]
        )
        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Blockchain.ScriptHash.SubscribeNotification.self,
            from: scripthashPayload,
            methodPath: "blockchain.scripthash.subscribe"
        )
    }

    @Test("Rejects undersized address and scripthash notification payloads")
    func rejectUndersizedAddressAndScriptHashNotifications() throws {
        let addressPayload = try makeJSONData(
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

        let scripthashPayload = try makeJSONData(
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

    @Test(
        "Rejects scripthash notifications with malformed subscription identifiers",
        arguments: [
            "script-hash",
            String(repeating: "g", count: 64)
        ]
    )
    func rejectScriptHashNotificationsWithMalformedSubscriptionIdentifiers(_ scriptHash: String) throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.scripthash.subscribe",
                "params": [scriptHash, "status"]
            ]
        )

        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Blockchain.ScriptHash.SubscribeNotification.self,
            from: payload,
            methodPath: "blockchain.scripthash.subscribe"
        )
    }
}
