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
        let regularEnvelope = try JSONDecoder().decode(Response.JSONRPCModel.GenericModel<String>.self, from: regularData)
        if case .regular(let regular) = try regularEnvelope.determineResponseType() {
            #expect(regular.result == "ok")
        } else {
            Issue.record("Expected regular response envelope")
        }

        let subscriptionData = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.headers.subscribe", "params": "update"]
        )
        let subscriptionEnvelope = try JSONDecoder().decode(Response.JSONRPCModel.GenericModel<String>.self, from: subscriptionData)
        if case .subscription(let subscription) = try subscriptionEnvelope.determineResponseType() {
            #expect(subscription.methodPath == "blockchain.headers.subscribe")
            #expect(subscription.result == "update")
        } else {
            Issue.record("Expected subscription response envelope")
        }

        let errorData = try jsonData(
            ["jsonrpc": "2.0", "id": identifier, "error": ["code": -1, "message": "boom"]]
        )
        let errorEnvelope = try JSONDecoder().decode(Response.JSONRPCModel.GenericModel<String>.self, from: errorData)
        if case .error(let rpcError) = try errorEnvelope.determineResponseType() {
            #expect(rpcError.error.code == -1)
            #expect(rpcError.error.message == "boom")
        } else {
            Issue.record("Expected error response envelope")
        }

        let emptyData = try jsonData(["jsonrpc": "2.0", "id": identifier])
        let emptyEnvelope = try JSONDecoder().decode(Response.JSONRPCModel.GenericModel<String?>.self, from: emptyData)
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
            Response.ResultModel.ServerModel.VersionModel.self,
            context: .init(methodPath: "server.version")
        )
        #expect(version.serverVersion == "Fulcrum 2.0")
        #expect(version.negotiatedProtocolVersion == ProtocolVersionModel(string: "1.5.3"))

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
            Response.ResultModel.ServerModel.FeaturesModel.self,
            context: .init(methodPath: "server.features")
        )
        #expect(features.maximumProtocolVersion == ProtocolVersionModel(string: "1.6.0"))
        #expect(features.minimumProtocolVersion == ProtocolVersionModel(string: "1.4.0"))
        #expect(features.hasCashTokens == true)
        #expect(features.hasDoubleSpendProofs == true)
    }

    @Test("Decodes headers/address/transaction/dsproof notifications")
    func decodeSubscriptionNotifications() throws {
        let headerPayload = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.headers.subscribe", "params": [["height": 1, "hex": String(repeating: "a", count: 160)]]]
        )
        let headerUpdate = try headerPayload.decode(
            Response.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel.self,
            context: .init(methodPath: "blockchain.headers.subscribe")
        )
        #expect(headerUpdate.subscriptionIdentifier == "blockchain.headers.subscribe")
        #expect(headerUpdate.blocks.count == 1)

        let addressPayload = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.address.subscribe", "params": ["bitcoincash:qtest", "status"]]
        )
        let addressUpdate = try addressPayload.decode(
            Response.ResultModel.BlockchainModel.AddressModel.SubscribeNotificationModel.self,
            context: .init(methodPath: "blockchain.address.subscribe")
        )
        #expect(addressUpdate.subscriptionIdentifier == "bitcoincash:qtest")
        #expect(addressUpdate.status == "status")

        let transactionPayload = try jsonData(
            ["jsonrpc": "2.0", "method": "blockchain.transaction.subscribe", "params": ["abc123", 42]]
        )
        let transactionUpdate = try transactionPayload.decode(
            Response.ResultModel.BlockchainModel.TransactionModel.SubscribeNotificationModel.self,
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
            Response.ResultModel.BlockchainModel.TransactionModel.DSProofModel.SubscribeNotificationModel.self,
            context: .init(methodPath: "blockchain.transaction.dsproof.subscribe")
        )
        #expect(dsProofUpdate.subscriptionIdentifier == "abc123")
        #expect(dsProofUpdate.proof?.transactionID == "abc123")
    }

    @Test("Decodes mempool fee histogram flexible number pairs")
    func decodeMempoolFeeHistogram() throws {
        let payload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": [[2.5, 2000], [1, 1000]]]
        )
        let histogram = try payload.decode(
            Response.ResultModel.MempoolModel.GetFeeHistogramModel.self,
            context: .init(methodPath: "mempool.get_fee_histogram")
        )
        #expect(histogram.histogram.count == 2)
        #expect(histogram.histogram[0].fee == 1.0)
        #expect(histogram.histogram[0].virtualSize == 1000)
        #expect(histogram.histogram[1].fee == 2.5)
        #expect(histogram.histogram[1].virtualSize == 2000)
    }

    @Test("Unexpected format errors include decode context")
    func enrichUnexpectedFormatWithContext() throws {
        let payload = try jsonData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": ["Fulcrum 2.0", "invalid"]]
        )

        do {
            _ = try payload.decode(
                Response.ResultModel.ServerModel.VersionModel.self,
                context: .init(methodPath: "server.version")
            )
            Issue.record("Expected decode to fail with unexpected format")
        } catch let error as Response.ResultModel.Error {
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
