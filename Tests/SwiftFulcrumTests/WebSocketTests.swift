import Testing
import Foundation
@testable import SwiftFulcrum

private extension URL {
    /// Any random main-net Fulcrum endpoint from bundled `servers.json`.
    static func randomFulcrum() async throws -> URL {
        guard let url = try await WebSocket.Server.getServerList().randomElement() else {
            throw Fulcrum.Error.transport(.setupFailed)
        }
        return url
    }
}

@Suite("WebSocket – Connection")
struct WebSocketConnectionTests {
    let socket: WebSocket
    
    init() async throws {
        self.socket = WebSocket(url: try await .randomFulcrum())
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
        let bad = WebSocket(url: URL(string: "wss://invalid-url")!, connectionTimeout: 1)
        await #expect(throws: Swift.Error.self) {
            try await bad.connect()
        }
        await bad.disconnect(with: nil)
    }
}

@Suite("WebSocket – Reconnector")
struct WebSocketReconnectorTests {
    
    // MARK: – Reusable sockets ------------------------------------------------
    /// A socket that should be able to reconnect successfully to a *real*
    /// Fulcrum endpoint.
    let healthy: WebSocket
    
    /// A socket that always points at an obviously-invalid host so every
    /// connection attempt is guaranteed to fail quickly.
    let hopeless: WebSocket
    
    init() async throws {
        // (1) happy-path socket — use any random main-net server, but keep the
        //     reconnection delays tiny so the test suite runs fast.
        self.healthy = WebSocket(
            url: try await .randomFulcrum(),
            reconnectConfiguration: .init(
                maximumReconnectionAttempts: 3,
                reconnectionDelay: 0.10,
                maximumDelay: 0.20,
                jitterRange: 1.0 ... 1.0
            ),
            connectionTimeout: 1
        )
        
        // (2) “always-fail” socket — the `.invalid` TLD is guaranteed not to
        //     resolve, so `URLSessionWebSocketTask` falls over immediately.
        self.hopeless = WebSocket(
            url: URL(string: "wss://example.invalid")!,
            reconnectConfiguration: .init(
                maximumReconnectionAttempts: 2,
                reconnectionDelay: 0.10,
                maximumDelay: 0.20,
                jitterRange: 1.0 ... 1.0
            ),
            connectionTimeout: 1
        )
    }
    
    // MARK: – Tests -----------------------------------------------------------
    @Test("reconnect succeeds after a clean disconnect")
    func reconnectHappyPath() async throws {
        try await healthy.connect()
        #expect(await healthy.isConnected)
        
        await healthy.disconnect(with: "Intentionally disconnected for unit-test")
        #expect(!(await healthy.isConnected))
        
        try await healthy.reconnector.attemptReconnection(for: healthy)
        #expect(await healthy.isConnected)
        
        await healthy.disconnect(with: nil)
    }
    
    @Test("reconnector stops after hitting the maximum-attempt limit")
    func reconnectFailurePath() async throws {
        // `attemptReconnection` should throw once it has
        //   * waited   (delay → connect →  ping-timeout) × N
        //   * reached  maxAttempts (2 in our config)
        await #expect(throws: Fulcrum.Error.self) {
            try await hopeless.reconnector.attemptReconnection(for: hopeless)
        }
        
        // We *should* still be in the disconnected state.
        #expect(!(await hopeless.isConnected))
    }
}
