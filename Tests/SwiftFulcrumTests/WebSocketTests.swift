import Testing
import Foundation
@testable import SwiftFulcrum

private extension URL {
    /// Any random main-net Fulcrum endpoint from bundled `servers.json`.
    static func randomFulcrum() throws -> URL {
        guard let url = try WebSocket.Server.getServerList().randomElement() else {
            throw WebSocket.Error.initializing(
                reason: .noURLAvailable,
                description: "No servers in servers.json")
        }
        return url
    }
}

@Suite("WebSocket – Connection")
struct WebSocketConnectionTests {
    let socket: WebSocket
    
    init() throws {
        self.socket = WebSocket(url: try .randomFulcrum())
    }
    
    @Test("connect → disconnect happy-path")
    func connectAndDisconnect() async throws {
        try await socket.connect()
        #expect(await socket.isConnected)
        
        await socket.disconnect(with: nil)
        #expect(!(await socket.isConnected))
    }
    
    @Test("explicit disconnect reason")
    func disconnectionWithReason() async throws {
        try await socket.connect()
        await socket.disconnect(with: "Force disconnection.")
        #expect(!(await socket.isConnected))
    }
    
    @Test("invalid URL fails")
    func faultyURL() async throws {
        let bad = WebSocket(url: URL(string: "wss://invalid-url")!)
        await #expect(throws: Swift.Error.self) {
            try await bad.connect()
        }
        await bad.disconnect(with: nil)
    }
}

@Suite("WebSocket – Reconnector")
struct WebSocketReconnectorTests {
    let goodSocket: WebSocket
    let badSocket: WebSocket
    
    init() throws {
        goodSocket = WebSocket(
            url: try .randomFulcrum(),
            reconnectConfiguration: .init(maxReconnectionAttempts: 3,
                                          reconnectionDelay: 0.25)  // snappy tests
        )
        
        // Invalid host guarantees failure without touching the network stack
        let bogus = URL(string: "wss://totally.invalid.host")!
        badSocket = WebSocket(
            url: bogus,
            reconnectConfiguration: .init(maxReconnectionAttempts: 2,
                                          reconnectionDelay: 0.1)
        )
    }
    
    // MARK: - Happy path -----------------------------------------------------
    @Test("reconnect succeeds after a clean disconnect")
    func reconnectSucceeds() async throws {
        try await goodSocket.connect()
        #expect(await goodSocket.isConnected)
        
        await goodSocket.disconnect(with: "Simulate link drop")
        #expect(!(await goodSocket.isConnected))
        
        try await goodSocket.reconnect()
        #expect(await goodSocket.isConnected)
        
        await goodSocket.disconnect(with: nil)  // tidy-up
    }
    
    // MARK: - Failure path ---------------------------------------------------
    @Test("reconnector stops after max attempts and surfaces an error")
    func reconnectFailsAndGivesUp() async throws {
        await #expect(throws: WebSocket.Error.self) {
            try await badSocket.reconnect()
        }
        #expect(!(await badSocket.isConnected))
    }
    
    // MARK: - Counter reset --------------------------------------------------
    @Test("resetReconnectionAttemptCount gives a fresh set of tries")
    func attemptCounterResets() async throws {
        // First round: burn through the allowed attempts.
        await #expect(throws: WebSocket.Error.self) {
            try await badSocket.reconnect()
        }
        
        // Manually reset the internal counter …
        await badSocket.reconnector.resetReconnectionAttemptCount()
        
        // … and verify we get another full cycle of attempts (should still fail).
        await #expect(throws: WebSocket.Error.self) {
            try await badSocket.reconnect()
        }
    }
}
