// ResponseDecodingValidator~RestoredSubscriptions.swift

import Foundation
import Testing
@testable import SwiftFulcrum

enum RestoredSubscriptionShape: CaseIterable, Equatable, Sendable {
    case headers, addressStatus, addressCleared, transactionConfirmed, transactionUnknown, doubleSpendProofFound, doubleSpendProofCleared
}

extension ResponseDecodingValidator {
    @Test("Restored snapshots decode through every supported update contract", arguments: RestoredSubscriptionShape.allCases)
    func decodeRestoredSubscriptionSnapshots(shape: RestoredSubscriptionShape) throws {
        let transactionHash = String(repeating: "a", count: 64)
        let methodPath: SubscriptionPathConfiguration
        let identifier: String?
        let result: Any
        switch shape {
        case .headers:
            methodPath = .headers
            identifier = nil
            result = ["height": 42, "hex": String(repeating: "b", count: 160)]
        case .addressStatus, .addressCleared:
            methodPath = .address
            identifier = "bitcoincash:restore-test-address"
            result = shape == .addressStatus ? "current-status" : NSNull()
        case .transactionConfirmed, .transactionUnknown:
            methodPath = .transaction
            identifier = transactionHash
            result = shape == .transactionConfirmed ? 42 : NSNull()
        case .doubleSpendProofFound, .doubleSpendProofCleared:
            methodPath = .transactionDoubleSpendProof
            identifier = transactionHash
            result = shape == .doubleSpendProofFound ? makeDSProofResult(transactionHash: transactionHash) : NSNull()
        }
        let requestIdentifier = UUID()
        let context = FulcrumNetworkClient.SubscriptionRestoreContext(
            subscriptionKey: .init(methodPath: methodPath, identifier: identifier),
            requestIdentifier: requestIdentifier,
            streamRegistrationIdentifier: UUID(),
            reconnectSuccessCount: 1,
            recoveryGeneration: 1,
            recoveryGenerationAuthority: .init(1)
        )
        let response = try makeJSONData(["jsonrpc": "2.0", "id": requestIdentifier.uuidString, "result": result])
        let restoredNotification = try context.makeNotification(from: response)
        let notification = try #require(restoredNotification)
        switch shape {
        case .headers:
            let update = try notification.decode(SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self)
            #expect(update.subscriptionIdentifier == methodPath.rawValue)
            #expect(update.blocks.map(\.height) == [42])
            #expect(update.blocks.first?.hex == String(repeating: "b", count: 160))
        case .addressStatus, .addressCleared:
            let update = try notification.decode(SwiftFulcrum.Response.Blockchain.Address.SubscribeNotification.self)
            #expect(update.subscriptionIdentifier == identifier)
            #expect(update.status == (shape == .addressStatus ? "current-status" : nil))
        case .transactionConfirmed, .transactionUnknown:
            let update = try notification.decode(SwiftFulcrum.Response.Blockchain.Transaction.SubscribeNotification.self)
            #expect(update.subscriptionIdentifier == transactionHash)
            #expect(update.height == (shape == .transactionConfirmed ? 42 : nil))
        case .doubleSpendProofFound, .doubleSpendProofCleared:
            let update = try notification.decode(SwiftFulcrum.Response.Blockchain.Transaction.DSProof.SubscribeNotification.self)
            #expect(update.subscriptionIdentifier == transactionHash)
            #expect(update.proof?.transactionID == (shape == .doubleSpendProofFound ? transactionHash : nil))
        }
    }

    @Test("Malformed restore results fail the original subscription result contract", arguments: [SubscriptionPathConfiguration.scriptHash, .address, .headers, .transaction, .transactionDoubleSpendProof])
    func rejectMalformedRestoredSubscriptionSnapshots(methodPath: SubscriptionPathConfiguration) throws {
        let requestIdentifier = UUID()
        let context = FulcrumNetworkClient.SubscriptionRestoreContext(
            subscriptionKey: .init(methodPath: methodPath, identifier: methodPath == .headers ? nil : String(repeating: "a", count: 64)),
            requestIdentifier: requestIdentifier,
            streamRegistrationIdentifier: UUID(),
            reconnectSuccessCount: 1,
            recoveryGeneration: 1,
            recoveryGenerationAuthority: .init(1)
        )
        let response = try makeJSONData(["jsonrpc": "2.0", "id": requestIdentifier.uuidString, "result": ["unexpected": "payload"]])
        #expect(throws: (any Swift.Error).self) {
            _ = try context.makeNotification(from: response)
        }
    }
}
