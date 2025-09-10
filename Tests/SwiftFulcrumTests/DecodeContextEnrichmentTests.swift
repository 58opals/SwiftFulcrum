import Foundation
import Testing
@testable import SwiftFulcrum

@Suite("Decode context enrichment")
struct DecodeContextEnrichmentTests {
    
    @Test
    func unexpectedFormat_includes_method_and_payload_size() async throws {
        let id = UUID()
        let method = Method.blockchain(.address(.subscribe(address: "bitcoincash:qq...")))
        let envelope: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id.uuidString,
            "result": ["bitcoincash:qq...", "deadbeef"]
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope, options: [])
        
        do {
            _ = try data.decode(
                Response.Result.Blockchain.Address.Subscribe.self,
                context: .init(methodPath: method.path)
            )
            Issue.record("expected unexpectedFormat")
        } catch let e as Response.Result.Error {
            switch e {
            case .unexpectedFormat(let message):
                #expect(message.contains("[method: \(method.path)]"))
                #expect(message.contains("[payload: \(data.count) B]"))
            default:
                Issue.record("unexpected error case: \(e)")
            }
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test
    func enriches_method_and_payload_for_regular_mismatch() throws {
        let methodPath = Method.blockchain(.address(.subscribe(address: "qxyz"))).path
        let bad = [
            "jsonrpc": "2.0",
            "id": "00000000-0000-0000-0000-000000000001",
            "result": ["qxyz", "deadbeef"]
        ] as [String: Any]
        let data = try JSONSerialization.data(withJSONObject: bad)

        do {
            _ = try data.decode(Response.Result.Blockchain.Address.Subscribe.self,
                                context: .init(methodPath: methodPath))
            Issue.record("expected unexpectedFormat to be thrown")
        } catch let err as Response.Result.Error {
            switch err {
            case .unexpectedFormat(let msg):
                #expect(msg.contains("[method: \(methodPath)]"))
                #expect(msg.contains("[payload: \(data.count) B]"))
            default:
                Issue.record("unexpected error: \(err)")
            }
        } catch {
            Issue.record("unexpected error type: \(error)")
        }
    }
    
    @Test
    func enriches_method_and_payload_for_subscription_notification_mismatch() throws {
        let methodPath = Method.blockchain(.address(.subscribe(address: "qxyz"))).path
        let bad = [
            "jsonrpc": "2.0",
            "method": methodPath,
            "params": "deadbeef"
        ] as [String: Any]
        let data = try JSONSerialization.data(withJSONObject: bad)

        do {
            _ = try data.decode(
                Response.Result.Blockchain.Address.SubscribeNotification.self,
                context: .init(methodPath: methodPath)
            )
            Issue.record("expected unexpectedFormat to be thrown")
        } catch let err as Response.Result.Error {
            switch err {
            case .unexpectedFormat(let msg):
                #expect(msg.contains("[method: \(methodPath)]"))
                #expect(msg.contains("[payload: \(data.count) B]"))
            default:
                Issue.record("unexpected error: \(err)")
            }
        } catch {
            Issue.record("unexpected error type: \(error)")
        }
    }
}
