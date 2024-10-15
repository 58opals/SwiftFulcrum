import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Basic Connection")
struct WebSocketConnectionTests {
    let webSocket: WebSocket
    
    init() throws {
        let url = try WebSocket.Server.getServerList().randomElement()!
        self.webSocket = WebSocket(url: url)
    }
    
    @Test func connection() async throws {
        try await self.webSocket.connect()
        
        let isConnected = await webSocket.isConnected
        #expect(isConnected)
        await self.webSocket.disconnect()
    }
    
    @Test func disconnection() async throws {
        try await self.webSocket.connect()
        await self.webSocket.disconnect(with: "Force disconnection.")
        
        let isConnected = await webSocket.isConnected
        #expect(!isConnected)
        await self.webSocket.disconnect()
    }
    
    @Test func testFaultyURLConnection() async throws {
        let webSocket = WebSocket(url: URL(string: "wss://invalid-url")!)
        
        await #expect(throws: WebSocket.Error.self) {
            try await webSocket.connect()
        }
        
        await webSocket.disconnect()
    }
}

@Suite("Reconnector")
struct WebSocketReconnectionTests {
    let webSocket: WebSocket
    
    init() throws {
        let url = try WebSocket.Server.getServerList().randomElement()!
        self.webSocket = WebSocket(url: url)
    }
    
    @Test func reconnection() async throws {
        let isConnected1 = await webSocket.isConnected
        #expect(!isConnected1)
        
        try await self.webSocket.connect()
        let isConnected2 = await webSocket.isConnected
        #expect(isConnected2)
        
        try await self.webSocket.reconnect()
        let isConnected3 = await webSocket.isConnected
        #expect(isConnected3)
        
        await self.webSocket.disconnect()
    }
    
    @Test func testMaxReconnectionAttempts() async throws {
        let faultyURL = URL(string: "wss://invalid-url")!
        let webSocket = WebSocket(url: faultyURL,
                                  reconnectConfiguration: .init(maxReconnectionAttempts: 2,
                                                                reconnectionDelay: 0.1))
        
        await #expect(throws: WebSocket.Error.self) {
            try await webSocket.reconnect()
        }
        
        await self.webSocket.disconnect()
    }
    
    @Test func testReconnectionDelay() async throws {
        let faultyURL = URL(string: "wss://invalid-url")!
        let reconnector = WebSocket.Reconnector(.init(maxReconnectionAttempts: 3, reconnectionDelay: 0.1))
        
        var previousReconnectionTime = Date().timeIntervalSince1970
        
        for attempt in 1...3 {
            do {
                print("Starting reconnection attempt \(attempt)")
                try await reconnector.attemptReconnection(for: WebSocket(url: faultyURL))
                let actualDelay = Date().timeIntervalSince1970 - previousReconnectionTime
                let expectedDelay = min(pow(2.0, Double(attempt)) * 0.1, 120)
                
                print("Expected delay: \(expectedDelay), Actual delay: \(actualDelay)")
                #expect(actualDelay >= expectedDelay, "Reconnection delay should be at least the expected delay.")
                previousReconnectionTime = Date().timeIntervalSince1970
            } catch {
                print("Caught error during reconnection: \(error)")
                if attempt == 3 {
                    if case WebSocket.Error.connection(_, .maximumAttemptsReached) = error {
                        print("Reconnection failed after maximum attempts, as expected.")
                        #expect(true, "Reconnection correctly failed after max attempts.")
                    } else {
                        print("Unexpected error: \(error)")
                        #expect(Bool(false), "Unexpected error during reconnection.")
                    }
                }
            }
        }
    }
}
