import Foundation
import Testing
@testable import SwiftFulcrum

@Suite("JSONRPC identifier extraction")
struct JSONRPCIdentifierExtractionTests {

    // Helper to build JSON data quickly
    private func makeJSON(_ object: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [])
    }

    @Test
    func chooses_uuid_when_id_present_and_method_missing() throws {
        let id = UUID()
        let data = try makeJSON([
            "jsonrpc": "2.0",
            "id": id.uuidString,
            "result": [:] as [String: Any]
        ])

        let identifier = try Response.JSONRPC.extractIdentifier(from: data)
        switch identifier {
        case .uuid(let got):
            #expect(got == id)
        default:
            Issue.record("expected .uuid, got \(identifier)")
        }
    }

    @Test
    func chooses_string_when_method_present_and_id_missing() throws {
        let method = "blockchain.headers.subscribe"
        let data = try makeJSON([
            "jsonrpc": "2.0",
            "method": method,
            "params": [] as [Any]
        ])

        let identifier = try Response.JSONRPC.extractIdentifier(from: data)
        switch identifier {
        case .string(let got):
            #expect(got == method)
        default:
            Issue.record("expected .string, got \(identifier)")
        }
    }

    @Test
    func throws_when_both_id_and_method_present() {
        let id = UUID()
        let method = "blockchain.headers.subscribe"
        let data = try! makeJSON([
            "jsonrpc": "2.0",
            "id": id.uuidString,
            "method": method
        ])

        do {
            _ = try Response.JSONRPC.extractIdentifier(from: data)
            Issue.record("expected throw, got success")
        } catch let error as Response.JSONRPC.Error {
            switch error {
            case .wrongResponseType:
                break
            default:
                Issue.record("unexpected error: \(error)")
            }
        } catch {
            Issue.record("unexpected non‑JSONRPC error: \(error)")
        }
    }

    @Test
    func throws_when_neither_id_nor_method_present() {
        let data = try! makeJSON([
            "jsonrpc": "2.0",
            "result": [:] as [String: Any]
        ])

        do {
            _ = try Response.JSONRPC.extractIdentifier(from: data)
            Issue.record("expected throw, got success")
        } catch let error as Response.JSONRPC.Error {
            switch error {
            case .wrongResponseType:
                break
            default:
                Issue.record("unexpected error: \(error)")
            }
        } catch {
            Issue.record("unexpected non‑JSONRPC error: \(error)")
        }
    }
}
