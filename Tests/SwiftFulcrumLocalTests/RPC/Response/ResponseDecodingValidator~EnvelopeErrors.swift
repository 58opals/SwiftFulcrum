// ResponseDecodingValidator~EnvelopeErrors.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Rejects envelopes with null error members")
    func rejectEnvelopeWithNullError() throws {
        let payload = try makeJSONData(
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
        let payload = try makeJSONData(
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
        let payload = try makeJSONData(
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
        let payload = try makeJSONData(
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
}
