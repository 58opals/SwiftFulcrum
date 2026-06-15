// ResponseDecodingValidator~BlockHeaders.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Rejects malformed block.headers batches instead of truncating them")
    func rejectMalformedBlockHeaderBatch() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "count": 2,
                    "hex": String(repeating: "a", count: 161),
                    "max": 2016
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Block.Headers.self,
                context: .init(methodPath: "blockchain.block.headers")
            )
        }
    }

    @Test("Rejects malformed block.headers batches with non-hex headers")
    func rejectMalformedBlockHeaderBatchWithNonHexHeaders() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "count": 1,
                    "hex": String(repeating: "g", count: 160),
                    "max": 2016
                ]
            ]
        )

        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Blockchain.Block.Headers.self,
            from: payload,
            methodPath: "blockchain.block.headers"
        )
    }

    @Test("Rejects block.headers counts larger than Int.max")
    func rejectBlockHeaderCountLargerThanIntMax() throws {
        let payload = Data(
            """
            {
                "jsonrpc": "2.0",
                "id": "\(UUID().uuidString)",
                "result": {
                    "count": 9223372036854775808,
                    "hex": "",
                    "max": 2016
                }
            }
            """.utf8
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Block.Headers.self,
                context: .init(methodPath: "blockchain.block.headers")
            )
        }
    }

    @Test(
        "Rejects malformed block.headers arrays",
        arguments: [
            String(repeating: "b", count: 159),
            String(repeating: "g", count: 160)
        ]
    )
    func rejectMalformedBlockHeaderArrayEntries(_ header: String) throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "count": 1,
                    "headers": [header],
                    "max": 2016
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Block.Headers.self,
                context: .init(methodPath: "blockchain.block.headers")
            )
        }
    }

    @Test("Rejects malformed block.header payloads with invalid header widths")
    func rejectMalformedBlockHeaderWithInvalidHeaderWidth() throws {
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": String(repeating: "a", count: 158)]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Block.Header.self,
                context: .init(methodPath: "blockchain.block.header")
            )
        }
    }

    @Test(
        "Rejects malformed block.header proof hashes",
        arguments: [
            (["abc123"], String(repeating: "d", count: 64)),
            ([String(repeating: "d", count: 64)], "abc123")
        ]
    )
    func rejectMalformedBlockHeaderProofHashes(branch: [String], root: String) throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "branch": branch,
                    "header": String(repeating: "c", count: 160),
                    "root": root
                ]
            ]
        )

        expectResponseResultDecodeFailure(
            SwiftFulcrum.Response.Blockchain.Block.Header.self,
            from: payload,
            methodPath: "blockchain.block.header"
        )
    }

    @Test("Rejects incomplete block.headers proof metadata")
    func rejectIncompleteBlockHeaderProofMetadata() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "count": 1,
                    "hex": String(repeating: "c", count: 160),
                    "max": 2016,
                    "branch": [String(repeating: "d", count: 64)]
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Blockchain.Block.Headers.self,
                context: .init(methodPath: "blockchain.block.headers")
            )
        }
    }

    @Test("Unexpected format errors include decode context")
    func enrichUnexpectedFormatWithContext() throws {
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": ["Fulcrum 2.0", "invalid"]]
        )

        do {
            _ = try payload.decode(
                SwiftFulcrum.Response.Server.Version.self,
                context: .init(methodPath: "server.version")
            )
            Issue.record("Expected decode to fail with unexpected format")
        } catch let error as ResponseResultDecodeError {
            guard case .unexpectedFormat(let message) = error else {
                Issue.record("Expected unexpected format, got \(error)")
                return
            }
            #expect(message.contains("[method: server.version]"))
            #expect(message.contains("[payload: "))
        }
    }
}
