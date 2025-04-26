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
        
        await #expect(throws: Swift.Error.self) {
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

@Suite("Reconnector - Refined")
struct WebSocketReconnectionRefinedTests {
    let webSocket: WebSocket
    
    init() throws {
        let url = try WebSocket.Server.getServerList().randomElement()!
        self.webSocket = WebSocket(url: url, reconnectConfiguration: .init(maxReconnectionAttempts: 3, reconnectionDelay: 1.0))
    }
    
    @Test func testReconnectionDelayWithTolerance() async throws {
        let faultyURL = URL(string: "wss://invalid-url")!
        let reconnector = WebSocket.Reconnector(.init(maxReconnectionAttempts: 3, reconnectionDelay: 1.0))
        var previousReconnectionTime = Date().timeIntervalSince1970
        let tolerance: Double = 0.1
        
        for attempt in 1...3 {
            do {
                print("Starting reconnection attempt \(attempt)")
                try await reconnector.attemptReconnection(for: WebSocket(url: faultyURL))
                let actualDelay = Date().timeIntervalSince1970 - previousReconnectionTime
                let expectedDelay = min(pow(2.0, Double(attempt)) * 1.0, 120)
                print("Expected delay: \(expectedDelay) s, Actual delay: \(actualDelay) s")
                #expect(actualDelay >= expectedDelay - tolerance && actualDelay <= expectedDelay + tolerance,
                        "Reconnection delay should be within tolerance of expected delay.")
                previousReconnectionTime = Date().timeIntervalSince1970
            } catch {
                print("Caught error during reconnection attempt \(attempt): \(error)")
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
    
    @Test func testReconnectionAttemptCountReset() async throws {
        let faultyURL = URL(string: "wss://invalid-url")!
        await #expect(throws: WebSocket.Error.self) {
            try await webSocket.reconnect(with: faultyURL)
        }
        
        let validURL = try WebSocket.Server.getServerList().randomElement()!
        let startTime = Date()
        try await webSocket.reconnect(with: validURL)
        let elapsed = Date().timeIntervalSince(startTime)
        
        #expect(elapsed > 1.0, "Elapsed time should be greater than the base delay after reset.")
        #expect(elapsed < 5.0, "Elapsed time should be within a reasonable threshold after reconnection.")
        
        await webSocket.disconnect()
    }
    
    @Test func testMessageHandlingPostReconnection() async throws {
        try await webSocket.connect()
        #expect(await webSocket.isConnected, "WebSocket should be connected initially.")
        
        let stream = await webSocket.messages()
        var iterator = stream.makeAsyncIterator()
        
        let testMessage1 = "Hello, world!"
        try await webSocket.send(string: testMessage1)
        
        guard let received1 = try await iterator.next() else {
            #expect(Bool(false), "No message was received for the first test message \(testMessage1).")
            return
        }
        
        switch received1 {
        case .string(let message):
            #expect(message.contains("Failed to parse Json from string: \(testMessage1)"), "Expected error response indicating failed JSON parsing for first message.")
        default:
            #expect(Bool(false), "Expected a string error message response.")
        }
        
        await webSocket.disconnect(with: "Testing disconnection.")
        #expect(!(await webSocket.isConnected), "WebSocket should be disconnected after forced disconnect.")
        
        try await webSocket.reconnect()
        #expect(await webSocket.isConnected, "WebSocket should be reconnected.")
        
        let newStream = await webSocket.messages()
        var newIterator = newStream.makeAsyncIterator()
        
        let testMessage2 = "Post-reconnection message"
        try await webSocket.send(string: testMessage2)
        
        guard let received2 = try await newIterator.next() else {
            #expect(Bool(false), "No message was received for the second test message \(testMessage2).")
            return
        }
        
        switch received2 {
        case .string(let message):
            #expect(message.contains("Failed to parse Json from string: \(testMessage2)"), "Expected error response indicating failed JSON parsing for second message.")
        default:
            #expect(Bool(false), "Expected a string error message response after reconnection.")
        }
        
        await webSocket.disconnect()
    }
}
