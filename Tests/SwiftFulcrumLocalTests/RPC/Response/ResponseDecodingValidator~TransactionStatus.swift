// ResponseDecodingValidator~TransactionStatus.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Rejects negative blockchain relay fees")
    func rejectNegativeBlockchainRelayFee() throws {
        let payload = try makeJSONData(
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
        let getHeightPayload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        let getHeight = try getHeightPayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.Height.self,
            context: .init(methodPath: "blockchain.transaction.get_height")
        )
        #expect(getHeight.height == nil)

        let subscribePayload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        let subscribe = try subscribePayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.Subscribe.self,
            context: .init(methodPath: "blockchain.transaction.subscribe")
        )
        #expect(subscribe.height == nil)

        let transactionHash = String(repeating: "a", count: 64)
        let notificationPayload = try makeJSONData(
            ["jsonrpc": "2.0", "method": "blockchain.transaction.subscribe", "params": [transactionHash, NSNull()]]
        )
        let notification = try notificationPayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.transaction.subscribe")
        )
        #expect(notification.transactionHash == transactionHash)
        #expect(notification.height == nil)
    }

    @Test("Rejects malformed transaction subscribe notification hashes")
    func rejectMalformedTransactionSubscribeNotificationHashes() throws {
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "method": "blockchain.transaction.subscribe", "params": ["abc123", NSNull()]]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.SubscribeNotification.self,
                context: .init(methodPath: "blockchain.transaction.subscribe")
            )
        }
    }

    @Test("Rejects malformed confirmed block hash payloads")
    func rejectMalformedConfirmedBlockHashPayloads() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "block_hash": String(repeating: "a", count: 62),
                    "block_header": String(repeating: "b", count: 160),
                    "block_height": 100
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.ConfirmedBlockHash.self,
                context: .init(methodPath: "blockchain.transaction.get_confirmed_blockhash")
            )
        }
    }

    @Test("Rejects reversed transaction subscribe notification payloads")
    func rejectReversedTransactionSubscribeNotificationPayload() throws {
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "method": "blockchain.transaction.subscribe", "params": [42, "abc123"]]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.SubscribeNotification.self,
                context: .init(methodPath: "blockchain.transaction.subscribe")
            )
        }
    }
}
