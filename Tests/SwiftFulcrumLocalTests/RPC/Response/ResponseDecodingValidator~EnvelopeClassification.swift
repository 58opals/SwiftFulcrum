// ResponseDecodingValidator~EnvelopeClassification.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Classifies regular/subscription/error/empty envelopes")
    func classifyEnvelopes() throws {
        let identifier = UUID().uuidString

        let regularData = try makeJSONData(["jsonrpc": "2.0", "id": identifier, "result": "ok"])
        let regularEnvelope = try JSONDecoder().decode(SwiftFulcrum.RPC.Response.JSONRPC.Generic<String>.self, from: regularData)
        if case .regular(let regular) = try regularEnvelope.determineResponseType() {
            #expect(regular.result == "ok")
        } else {
            Issue.record("Expected regular response envelope")
        }

        let subscriptionData = try makeJSONData(
            ["jsonrpc": "2.0", "method": "blockchain.headers.subscribe", "params": "update"]
        )
        let subscriptionEnvelope = try JSONDecoder().decode(SwiftFulcrum.RPC.Response.JSONRPC.Generic<String>.self, from: subscriptionData)
        if case .subscription(let subscription) = try subscriptionEnvelope.determineResponseType() {
            #expect(subscription.methodPath == "blockchain.headers.subscribe")
            #expect(subscription.result == "update")
        } else {
            Issue.record("Expected subscription response envelope")
        }

        let errorData = try makeJSONData(
            ["jsonrpc": "2.0", "id": identifier, "error": ["code": -1, "message": "boom"]]
        )
        let errorEnvelope = try JSONDecoder().decode(SwiftFulcrum.RPC.Response.JSONRPC.Generic<String>.self, from: errorData)
        if case .error(let rpcError) = try errorEnvelope.determineResponseType() {
            #expect(rpcError.error.code == -1)
            #expect(rpcError.error.message == "boom")
        } else {
            Issue.record("Expected error response envelope")
        }

        let nullIDErrorData = try makeJSONData(
            ["jsonrpc": "2.0", "id": NSNull(), "error": ["code": -32700, "message": "parse error"]]
        )
        let nullIDErrorEnvelope = try JSONDecoder().decode(
            SwiftFulcrum.RPC.Response.JSONRPC.Generic<String>.self,
            from: nullIDErrorData
        )
        if case .error(let rpcError) = try nullIDErrorEnvelope.determineResponseType() {
            #expect(rpcError.id == nil)
            #expect(rpcError.error.code == -32700)
            #expect(rpcError.error.message == "parse error")
        } else {
            Issue.record("Expected nil-id error response envelope")
        }

        let emptyData = try makeJSONData(["jsonrpc": "2.0", "id": identifier])
        let emptyEnvelope = try JSONDecoder().decode(SwiftFulcrum.RPC.Response.JSONRPC.Generic<String?>.self, from: emptyData)
        if case .empty(let id) = try emptyEnvelope.determineResponseType() {
            #expect(id.uuidString == identifier)
        } else {
            Issue.record("Expected empty response envelope")
        }
    }

    @Test("Rejects non-JSON-RPC-2.0 envelopes")
    func rejectNonJSONRPC2Envelope() throws {
        let payload = try makeJSONData(["jsonrpc": "1.0", "id": UUID().uuidString, "result": "ok"])

        #expect(throws: DecodingError.self) {
            _ = try payload.decode(String.self, context: .init(methodPath: "server.banner"))
        }
    }

    @Test("Rejects non-JSON-RPC-2.0 identifier envelopes")
    func rejectNonJSONRPC2IdentifierEnvelope() throws {
        let payload = try makeJSONData(["jsonrpc": "1.0", "id": UUID().uuidString, "result": true])

        #expect(throws: DecodingError.self) {
            _ = try SwiftFulcrum.RPC.Response.JSONRPC.extractIdentifier(from: payload)
        }
    }

    @Test("Rejects non-JSON-RPC-2.0 erased envelopes")
    func rejectNonJSONRPC2ErasedEnvelope() throws {
        let payload = try makeJSONData(["jsonrpc": "1.0", "id": UUID().uuidString, "result": true])

        #expect(throws: DecodingError.self) {
            _ = try SwiftFulcrum.RPC.Response.JSONRPC.classifyErasedResponse(from: payload)
        }
    }

    @Test("Rejects envelopes that contain both result and error")
    func rejectEnvelopeWithResultAndError() throws {
        let payload = try makeJSONData(
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
        let payload = try makeJSONData(
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

    @Test("Classifies erased error envelopes with null identifiers")
    func classifyErasedErrorEnvelopesWithNullIdentifiers() throws {
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "id": NSNull(), "error": ["code": -32700, "message": "parse error"]]
        )

        let response = try SwiftFulcrum.RPC.Response.JSONRPC.classifyErasedResponse(from: payload)

        if case .error(.rpc(let rpcError)) = response {
            #expect(rpcError.id == nil)
            #expect(rpcError.code == -32700)
            #expect(rpcError.message == "JSON-RPC server error message redacted (11 UTF-8 bytes)")
            #expect(rpcError.messageByteCount == 11)
        } else {
            Issue.record("Expected nil-id erased error response")
        }
    }
}
