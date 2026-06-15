// ResponseDecodingValidator~Headers.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Decodes blockchain header lookup")
    func decodeBlockchainHeaderLookup() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "height": 1,
                    "hex": String(repeating: "a", count: 160)
                ]
            ]
        )

        let header = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Header.Lookup.self,
            context: .init(methodPath: "blockchain.header.get")
        )

        #expect(header.height == 1)
        #expect(header.hex == String(repeating: "a", count: 160))
    }

    @Test("Rejects malformed blockchain header lookups with invalid header widths")
    func rejectMalformedBlockchainHeaderLookupWithInvalidHeaderWidth() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "height": 1,
                    "hex": String(repeating: "a", count: 158)
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Header.Lookup.self,
                context: .init(methodPath: "blockchain.header.get")
            )
        }
    }

    @Test("Decodes blockchain headers tip")
    func decodeBlockchainHeadersTip() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "height": 2,
                    "hex": String(repeating: "b", count: 160)
                ]
            ]
        )

        let tip = try payload.decode(
            SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
            context: .init(methodPath: "blockchain.headers.get_tip")
        )

        #expect(tip.height == 2)
        #expect(tip.hex == String(repeating: "b", count: 160))
    }

    @Test("Rejects malformed blockchain headers tips with invalid header widths")
    func rejectMalformedBlockchainHeadersTipWithInvalidHeaderWidth() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "height": 2,
                    "hex": String(repeating: "b", count: 158)
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
                context: .init(methodPath: "blockchain.headers.get_tip")
            )
        }
    }

    @Test("Rejects malformed blockchain headers tips with non-hex headers")
    func rejectMalformedBlockchainHeadersTipWithNonHexHeader() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "height": 2,
                    "hex": String(repeating: "g", count: 160)
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
                context: .init(methodPath: "blockchain.headers.get_tip")
            )
        }
    }
}
