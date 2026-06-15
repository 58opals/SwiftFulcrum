// OpalDiagnosticsSwiftFulcrumValidator~Codec.swift

import Foundation
import OpalDiagnostics
import Testing
@testable import SwiftFulcrum

extension OpalDiagnosticsSwiftFulcrumValidator {
    @Test("JSON-RPC request encoding records a traced diagnostics event")
    func validateRequestEncodingRecordsDiagnosticsEvent() throws {
        try withDiagnosticsCapture {
            let requestID = UUID()
            let request = SwiftFulcrum.RPC.Method.server(.ping).createRequest(with: requestID)
            let payload = try #require(request.data)

            let traceID = OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestID)
            let record = try #require(findDiagnosticRecord(named: .swiftFulcrumJSONRPCRequestEncoded, traceID: traceID))
            #expect(record.category == .swiftFulcrumJSONRPC)
            #expect(record.traceID == traceID)
            #expect(findField("method_path", in: record)?.value == "server.ping")
            #expect(findField("request_id", in: record)?.value == requestID.uuidString)
            #expect(findField("byte_count", in: record)?.value == String(payload.count))
        }
    }

    @Test("JSON-RPC request encoding failures record a stable error code")
    func recordStableErrorCodeForRequestEncodingFailure() throws {
        try withDiagnosticsCapture {
            let requestID = UUID()
            let request = FulcrumRequest(
                id: requestID,
                method: SwiftFulcrum.RPC.Method.server(.ping),
                params: ThrowingParametersModel()
            )
            #expect(request.data == nil)

            let traceID = OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestID)
            let record = try #require(findDiagnosticRecord(named: .swiftFulcrumJSONRPCRequestEncodeFailed, traceID: traceID))
            #expect(record.category == .swiftFulcrumJSONRPC)
            #expect(findField("method_path", in: record)?.value == "server.ping")
            record.expectErrorCode(.jsonRPCEncodeFailed)
            #expect(findField("error_message", in: record)?.value == "<redacted>")
        }
    }

    @Test("JSON-RPC response decoding records success and redacted failures")
    func validateResponseDecodingRecordsDiagnosticsEvents() throws {
        try withDiagnosticsCapture {
            let requestID = UUID()
            let successPayload = try makeJSONData(["jsonrpc": "2.0", "id": requestID.uuidString, "result": "ok"])
            let decoded = try successPayload.decode(String.self, context: .init(methodPath: "server.banner"))
            #expect(decoded == "ok")

            let traceID = OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestID)
            let successRecord = try #require(findDiagnosticRecord(named: .swiftFulcrumJSONRPCResponseDecoded, traceID: traceID))
            #expect(successRecord.category == .swiftFulcrumJSONRPC)
            #expect(successRecord.traceID == traceID)
            #expect(findField("method_hint", in: successRecord)?.value == "server.banner")
            #expect(findField("byte_count", in: successRecord)?.value == String(successPayload.count))

            OpalDiagnostics.clearRecentRecords()

            let failurePayload = try makeJSONData(["jsonrpc": "2.0", "id": requestID.uuidString, "result": "not-an-int"])
            #expect(throws: DecodingError.self) {
                _ = try failurePayload.decode(Int.self, context: .init(methodPath: "server.banner"))
            }

            let failureRecord = try #require(findDiagnosticRecord(named: .swiftFulcrumJSONRPCResponseDecodeFailed, traceID: traceID))
            #expect(failureRecord.category == .swiftFulcrumJSONRPC)
            #expect(failureRecord.traceID == traceID)
            #expect(findField("method_hint", in: failureRecord)?.value == "server.banner")
            failureRecord.expectErrorCode(.jsonRPCDecodeFailed)
            #expect(findField("error_type", in: failureRecord)?.privacy == .public)
            #expect(findField("error_message", in: failureRecord)?.value == "<redacted>")
        }
    }

    @Test("JSON-RPC error responses are not recorded as decode failures")
    func verifyRPCErrorResponsesAreNotRecordedAsDecodeFailures() throws {
        try withDiagnosticsCapture {
            let requestID = UUID()
            let errorPayload = try makeJSONData([
                "jsonrpc": "2.0",
                "id": requestID.uuidString,
                "error": ["code": 1, "message": "server rejected request"]
            ])

            #expect(throws: SwiftFulcrum.Client.Error.self) {
                _ = try errorPayload.decode(String.self, context: .init(methodPath: "server.banner"))
            }

            let traceID = OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestID)
            let decodedRecord = try #require(findDiagnosticRecord(named: .swiftFulcrumJSONRPCResponseDecoded, traceID: traceID))
            #expect(decodedRecord.category == .swiftFulcrumJSONRPC)
            #expect(findField("method_hint", in: decodedRecord)?.value == "server.banner")
            decodedRecord.expectErrorCode(.jsonRPCServerError)
            #expect(findField("error_message", in: decodedRecord) == nil)
            #expect(OpalDiagnostics.recentRecords(matching: .init(event: .swiftFulcrumJSONRPCResponseDecodeFailed)).isEmpty)
        }
    }
}
