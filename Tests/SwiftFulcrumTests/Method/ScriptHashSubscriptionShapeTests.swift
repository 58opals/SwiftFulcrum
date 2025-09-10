import Foundation
import Testing
@testable import SwiftFulcrum

// Minimal helpers local to this file to avoid name collisions
private func shJSON(_ object: Any) throws -> Data {
    try JSONSerialization.data(withJSONObject: object, options: [])
}

@discardableResult
private func shExpectUnexpectedFormat(_ error: Swift.Error,
                                      contains needle: String,
                                      method: String? = nil) -> Bool {
    guard let e = error as? Response.Result.Error else {
        Issue.record("wrong error type: \(error)")
        return false
    }
    switch e {
    case .unexpectedFormat(let message):
        if let method { #expect(message.contains("[method: \(method)]")) }
        #expect(message.contains(needle))
        return true
    default:
        Issue.record("expected unexpectedFormat, got \(e)")
        return false
    }
}

// MARK: - blockchain.scripthash.subscribe shape guards

@Suite("JSON‑RPC scripthash subscribe shape guards")
struct ScriptHashSubscriptionShapeTests {
    
    @Test
    func scripthash_initial_accepts_status_string() throws {
        let sh = String(repeating: "0", count: 64)
        let path = Method.blockchain(.scripthash(.subscribe(scripthash: sh))).path
        let payload = try shJSON([
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "result": "deadbeef"
        ])
        
        let value = try payload.decode(
            Response.Result.Blockchain.ScriptHash.Subscribe.self,
            context: .init(methodPath: path)
        )
        #expect(value.status == "deadbeef")
    }
    
    @Test
    func scripthash_initial_rejects_pair() throws {
        let sh = String(repeating: "a", count: 64)
        let path = Method.blockchain(.scripthash(.subscribe(scripthash: sh))).path
        let payload = try shJSON([
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "result": [sh, "abcd"]
        ])
        
        do {
            _ = try payload.decode(
                Response.Result.Blockchain.ScriptHash.Subscribe.self,
                context: .init(methodPath: path)
            )
            Issue.record("expected failure")
        } catch {
            _ = shExpectUnexpectedFormat(error,
                                         contains: "Expected a status string",
                                         method: path)
        }
    }
    
    @Test
    func scripthash_notification_accepts_pair() throws {
        let sh = String(repeating: "b", count: 64)
        let path = Method.blockchain(.scripthash(.subscribe(scripthash: sh))).path
        let payload = try shJSON([
            "jsonrpc": "2.0",
            "method": path,
            "params": [sh, "abcd"]
        ])
        
        let n = try payload.decode(
            Response.Result.Blockchain.ScriptHash.SubscribeNotification.self,
            context: .init(methodPath: path)
        )
        #expect(n.subscriptionIdentifier == sh)
        #expect(n.status == "abcd")
    }
    
    @Test
    func scripthash_notification_rejects_single_status() throws {
        let sh = String(repeating: "c", count: 64)
        let path = Method.blockchain(.scripthash(.subscribe(scripthash: sh))).path
        let payload = try shJSON([
            "jsonrpc": "2.0",
            "method": path,
            "params": "deadbeef"
        ])
        
        do {
            _ = try payload.decode(
                Response.Result.Blockchain.ScriptHash.SubscribeNotification.self,
                context: .init(methodPath: path)
            )
            Issue.record("expected failure")
        } catch {
            _ = shExpectUnexpectedFormat(error,
                                         contains: "Expected scripthash and status pair",
                                         method: path)
        }
    }
}

// MARK: - Method ↔︎ path mapping for scripthash

@Suite("Scripthash method ↔︎ path mapping")
struct ScriptHashPathMappingTests {
    
    @Test
    func paths_match_expected() {
        let sh = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        let cases: [(SwiftFulcrum.Method, String)] = [
            (.blockchain(.scripthash(.getBalance(scripthash: sh, tokenFilter: .include))), "blockchain.scripthash.get_balance"),
            (.blockchain(.scripthash(.getFirstUse(scripthash: sh))), "blockchain.scripthash.get_first_use"),
            (.blockchain(.scripthash(.getHistory(scripthash: sh, fromHeight: 0, toHeight: 10, includeUnconfirmed: false))), "blockchain.scripthash.get_history"),
            (.blockchain(.scripthash(.getMempool(scripthash: sh))), "blockchain.scripthash.get_mempool"),
            (.blockchain(.scripthash(.listUnspent(scripthash: sh, tokenFilter: .include))), "blockchain.scripthash.listunspent"),
            (.blockchain(.scripthash(.subscribe(scripthash: sh))), "blockchain.scripthash.subscribe"),
            (.blockchain(.scripthash(.unsubscribe(scripthash: sh))), "blockchain.scripthash.unsubscribe"),
        ]
        for (method, expected) in cases { #expect(method.path == expected) }
    }
}

// MARK: - Client subscription routing (simulated notification)

@Suite("Client scripthash subscription routing")
struct ScriptHashClientRoutingTests {
    
    // Simple no‑op metrics to satisfy initializers without pulling in other test helpers
    actor NullMetrics: MetricsCollectable {
        func didConnect(url: URL) async {}
        func didDisconnect(url: URL, closeCode: URLSessionWebSocketTask.CloseCode?, reason: String?) async {}
        func didSend(url: URL, message: URLSessionWebSocketTask.Message) async {}
        func didReceive(url: URL, message: URLSessionWebSocketTask.Message) async {}
        func didPing(url: URL, error: Error?) async {}
    }
    
    @Test
    func subscription_receives_routed_notification() async throws {
        // Pick a random server the same way Fulcrum does
        let servers = try await WebSocket.Server.getServerList()
        guard let url = servers.randomElement() else {
            Issue.record("no Fulcrum servers available")
            return
        }
        
        let metrics = NullMetrics()
        let logger = Log.NoOpHandler()
        let webSocket = WebSocket(
            url: url,
            configuration: .init(metrics: metrics, logger: logger),
            reconnectConfiguration: .init(maximumReconnectionAttempts: 2,
                                          reconnectionDelay: 0,
                                          maximumDelay: 0,
                                          jitterRange: 1...1),
            connectionTimeout: 8.0
        )
        let client = Client(webSocket: webSocket, metrics: metrics, logger: logger)
        
        try await client.start()
        #expect(await webSocket.isConnected)
        
        let sh = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        typealias Initial = Response.Result.Blockchain.ScriptHash.Subscribe
        typealias Notification = Response.Result.Blockchain.ScriptHash.SubscribeNotification
        
        let (_, _, stream): (UUID, Initial, AsyncThrowingStream<Notification, any Error>) =
        try await client.subscribe(method: .blockchain(.scripthash(.subscribe(scripthash: sh))))
        
        var iterator = stream.makeAsyncIterator()
        
        // Simulate server notification
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "blockchain.scripthash.subscribe",
            "params": [sh, "cafebabe"]
        ]
        try await client.handleMessage(.data(shJSON(payload)))
        
        let n = try await iterator.next()
        #expect(n != nil)
        #expect(n!.subscriptionIdentifier == sh)
        #expect(n!.status == "cafebabe")
        
        await client.stop()
    }
}
