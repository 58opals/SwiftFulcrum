// ResponseDecodingValidator~DSProofNotifications.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Decodes missing double-spend proof as not found")
    func decodeMissingDSProofAsNotFound() throws {
        let getPayload = try makeJSONData(
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

        let subscribePayload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": NSNull()]
        )
        let subscribe = try subscribePayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Subscribe.self,
            context: .init(methodPath: "blockchain.transaction.dsproof.subscribe")
        )
        #expect(subscribe.proof == nil)

        let transactionHash = String(repeating: "d", count: 64)
        let notificationPayload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.transaction.dsproof.subscribe",
                "params": [transactionHash, NSNull()]
            ]
        )
        let notification = try notificationPayload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.DSProof.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.transaction.dsproof.subscribe")
        )
        #expect(notification.transactionHash == transactionHash)
        #expect(notification.proof == nil)
    }

    @Test("Rejects malformed DSProof subscribe notification hashes")
    func rejectMalformedDSProofSubscribeNotificationHashes() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.transaction.dsproof.subscribe",
                "params": ["abc123", NSNull()]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Transaction.DSProof.SubscribeNotification.self,
                context: .init(methodPath: "blockchain.transaction.dsproof.subscribe")
            )
        }
    }

    @Test("Rejects mismatched DSProof subscribe notification proof hashes")
    func rejectMismatchedDSProofSubscribeNotificationProofHashes() throws {
        let routeTransactionHash = String(repeating: "1", count: 64)
        let proofTransactionHash = String(repeating: "2", count: 64)
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.transaction.dsproof.subscribe",
                "params": [
                    routeTransactionHash,
                    makeDSProofResult(transactionHash: proofTransactionHash)
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

    @Test("Rejects reversed DSProof subscribe notification payloads")
    func rejectReversedDSProofSubscribeNotificationPayload() throws {
        let transactionHash = String(repeating: "f", count: 64)
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "method": "blockchain.transaction.dsproof.subscribe",
                "params": [
                    makeDSProofResult(transactionHash: transactionHash),
                    transactionHash
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
        let proofTransactionHash = String(repeating: "e", count: 64)
        let proof = makeDSProofResult(transactionHash: proofTransactionHash)
        let payload = try makeJSONData(
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
            ) == proofTransactionHash
        )

        let notification = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Transaction.DSProof.SubscribeNotification.self,
            context: .init(methodPath: "blockchain.transaction.dsproof.subscribe")
        )
        #expect(notification.subscriptionIdentifier == proofTransactionHash)
        #expect(notification.transactionHash == proofTransactionHash)
        #expect(notification.proof?.transactionID == proofTransactionHash)
    }
}
