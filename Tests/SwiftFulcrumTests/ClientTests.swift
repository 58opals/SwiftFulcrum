import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Client Tests")
struct ClientTests {
    let client: Client
    
    // Initializes the client with a valid WebSocket connection.
    init() async throws {
        let url = try WebSocket.Server.getServerList().randomElement()!
        let webSocket = WebSocket(url: url)
        self.client = Client(webSocket: webSocket)
        try await self.client.start()
    }
    
    @Test func testClientConnection() async throws {
        // Verify that the client establishes an active connection.
        let isConnected = await client.webSocket.isConnected
        #expect(isConnected, "Client should establish a WebSocket connection.")
    }
    
    @Test func testReconnection() async throws {
        // Set up a faulty WebSocket using an invalid URL.
        let faultyURL = URL(string: "wss://invalid-url")!
        // Use a valid URL for a successful reconnection later.
        let validURL = URL(string:"wss://electroncash.de:60002")!
        
        let faultyWebSocket = WebSocket(url: faultyURL)
        let faultyClient = Client(webSocket: faultyWebSocket)
        
        // Expect a failure when attempting to connect using an invalid URL.
        await #expect(throws: WebSocket.Error.self, "Connecting to an invalid URL should throw an error.") {
            try await faultyClient.webSocket.connect()
        }
        
        // Expect a failure when attempting to reconnect from a failed connection.
        await #expect(throws: WebSocket.Error.self, "Reconnecting on a failed connection should throw an error.") {
            try await faultyClient.webSocket.reconnect()
        }
        
        // Reconnect with a valid URL, which should succeed and reset the reconnection logic.
        try await faultyClient.webSocket.reconnect(with: validURL)
        let isConnected = await faultyClient.webSocket.isConnected
        #expect(isConnected, "After reconnecting with a valid URL, the WebSocket should be connected.")
    }
}

@Suite("Shutdown / stop() tests")
struct StopLogicTests {
    @Test func testStopClosesConnection() async throws {
        let fulcrum = try Fulcrum()
        try await fulcrum.start()
        
        #expect(await fulcrum.client.webSocket.isConnected,
                "Socket should be connected after start()")
        
        await fulcrum.stop()
        
        #expect(!(await fulcrum.client.webSocket.isConnected),
                "Socket should be disconnected after stop()")
        #expect(!(await fulcrum.isRunning),
                "isRunning flag should be false after stop()")
    }
    
    @Test func testPendingRPCFinishesWithConnectionClosed() async throws {
        let fulcrum = try Fulcrum()
        try await fulcrum.start()
        
        let callTask = Task {
            try await fulcrum.submit(
                method: .blockchain(.relayFee),
                responseType: Response.JSONRPC.Generic<
                    Response.JSONRPC.Result.Blockchain.RelayFee>.self
            )
        }

        await fulcrum.stop()

        await #expect(throws: Error.self, "callTask should throw once stop() is called") {
            _ = try await callTask.value
        }
    }
    
    @Test func testSubscriptionStreamEndsOnStop() async throws {
        let fulcrum = try Fulcrum()
        try await fulcrum.start()
        
        let (_, _, stream) = try await fulcrum.submit(
            method: .blockchain(.headers(.subscribe)),
            notificationType: Response.JSONRPC.Generic<
            Response.JSONRPC.Result.Blockchain.Headers.Subscribe>.self)
        
        await fulcrum.stop()
        
        await #expect(throws: Fulcrum.Error.connectionClosed) {
            for try await _ in stream {
                /* never reached */
            }
        }
    }
}
