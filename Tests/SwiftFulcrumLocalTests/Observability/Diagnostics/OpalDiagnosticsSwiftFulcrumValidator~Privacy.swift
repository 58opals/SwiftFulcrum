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
}
