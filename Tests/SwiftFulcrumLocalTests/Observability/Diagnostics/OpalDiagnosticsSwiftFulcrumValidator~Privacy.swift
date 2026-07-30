// OpalDiagnosticsSwiftFulcrumValidator~Privacy.swift

import Foundation
import OpalDiagnostics
import Testing
@testable import SwiftFulcrum

extension OpalDiagnosticsSwiftFulcrumValidator {
    @Test("Error diagnostics summarize payload failures without retaining raw contents")
    func summarizePayloadErrorsWithoutRetainingRawContents() throws {
        let rawContents = "raw-chain-payload-should-not-be-retained"
        let error = JSONRPCCodec.Error.decodingFailure(
            reason: .unexpectedFormat,
            data: Data(rawContents.utf8),
            description: rawContents
        )

        let fields = OpalDiagnostics.Field.swiftFulcrumErrorFields(error)
        let message = try #require(fields.first { $0.name == "error_message" }?.value)

        #expect(message.contains(rawContents) == false)
    }

    @Test("Verbose transaction mismatch diagnostics do not retain raw hex")
    func verifyVerboseTransactionMismatchDiagnosticsDoNotRetainRawHex() throws {
        try withDiagnosticsCapture {
            let requestID = UUID()
            let rawHex = "01000000deadbeef"
            let payload = try makeJSONData([
                "jsonrpc": "2.0",
                "id": requestID.uuidString,
                "result": rawHex
            ])

            #expect(throws: ResponseResultDecodeError.self) {
                _ = try payload.decode(
                    SwiftFulcrum.Response.Blockchain.Transaction.Verbose.self,
                    context: .init(methodPath: "blockchain.transaction.get")
                )
            }

            let traceID = OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestID)
            let record = try #require(findDiagnosticRecord(named: .swiftFulcrumJSONRPCResponseDecodeFailed, traceID: traceID))
            let message = try #require(findField("error_message", in: record)?.value)
            #expect(message.contains(rawHex) == false)
            #expect(message == "<redacted>")
        }
    }

    @Test("RPA diagnostics retain no wallet-identifying data", .timeLimit(.minutes(1)))
    func verifyRPADiagnosticsDoNotRetainWalletIdentifyingData() async throws {
        try await withDiagnosticsCapture {
            let transport = TransportTestActor()
            let client = FulcrumNetworkClient(
                transport: transport,
                protocolNegotiation: .init()
            )
            try await startAndCompleteProtocolNegotiation(
                client: client,
                transport: transport,
                negotiatedProtocolVersion: "1.6.0",
                includesRPA: true
            )
            OpalDiagnostics.clearRecentRecords()

            let prefix = "AbCd"
            let transactionHash =
                "acc3758bd2a26f869fcc67d48ff30b96464d476bca82c1cd6656e7d506816412"
            let method = SwiftFulcrum.RPC.Method.blockchain(
                .rpa(
                    .getHistory(
                        prefix: prefix,
                        fromHeight: 825_000,
                        toHeight: nil
                    )
                )
            )
            let requestTask = Task<
                (UUID, SwiftFulcrum.Response.Blockchain.RPA.History),
                Swift.Error
            > {
                try await client.call(method: method)
            }

            let request = try TransportTestActor.decodeJSONObject(
                from: await transport.dequeueOutgoing()
            )
            let identifier = try #require(request["id"] as? String)
            let response = try TransportTestActor.encodeResponsePayload(
                identifier: identifier,
                result: [
                    [
                        "height": 825_000,
                        "tx_hash": transactionHash
                    ]
                ]
            )
            await transport.enqueueIncoming(.data(response))
            _ = try await requestTask.value

            let completePaycode = "complete-paycode-wallet-secret"
            await #expect(throws: SwiftFulcrum.Client.Error.self) {
                let _: (UUID, SwiftFulcrum.Response.Blockchain.RPA.Mempool) =
                    try await client.call(
                        method: .blockchain(
                            .rpa(.getMempool(prefix: completePaycode))
                        )
                    )
            }

            let rawWalletTransaction = "01000000deadbeef"
            let malformedResponseTask = Task<
                (UUID, SwiftFulcrum.Response.Blockchain.RPA.History),
                Swift.Error
            > {
                try await client.call(method: method)
            }
            let malformedRequest = try TransportTestActor.decodeJSONObject(
                from: await transport.dequeueOutgoing()
            )
            let malformedIdentifier = try #require(
                malformedRequest["id"] as? String
            )
            let malformedResponse =
                try TransportTestActor.encodeResponsePayload(
                    identifier: malformedIdentifier,
                    result: [
                        [
                            "height": 825_000,
                            "tx_hash": rawWalletTransaction
                        ]
                    ]
                )
            await transport.enqueueIncoming(.data(malformedResponse))
            await #expect(throws: ResponseResultDecodeError.self) {
                _ = try await malformedResponseTask.value
            }

            let fields = OpalDiagnostics.recentRecords.flatMap(\.fields)
            #expect(
                fields.contains {
                    $0.name == "params" || $0.name == "rpa_prefix"
                } == false
            )
            for field in fields
                where field.name != "client_id"
                    && field.name != "request_id" {
                #expect(field.value.contains(prefix) == false)
                #expect(field.value.contains(transactionHash) == false)
                #expect(field.value.contains(completePaycode) == false)
                #expect(field.value.contains(rawWalletTransaction) == false)
            }

            await client.stop()
        }
    }
}
