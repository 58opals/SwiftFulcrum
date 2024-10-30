import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Client Tests")
struct ClientTests {
    let client: Client
    
    init() async throws {
        let url = try WebSocket.Server.getServerList().randomElement()!
        let webSocket = WebSocket(url: url)
        self.client = Client(webSocket: webSocket)
        
        try await self.client.start()
    }
    
    @Test func testClientConnection() async throws {
        let isConnected = await client.webSocket.isConnected
        
        #expect(isConnected, "Client should establish a WebSocket connection.")
    }
    
    @Test func testReconnection() async throws {
        let faultyWebSocket = WebSocket(url: URL(string: "wss://invalid-url")!)
        let validURL = URL(string:"wss://electroncash.de:60002")!
        
        let faultyClient = Client(webSocket: faultyWebSocket)
        
        await #expect(throws: WebSocket.Error.self) {
            try await faultyClient.webSocket.connect()
        }
        
        await #expect(throws: WebSocket.Error.self) {
            try await faultyClient.webSocket.reconnect()
        }
        
        try await faultyClient.webSocket.reconnect(with: validURL)
        let isConnected = await faultyClient.webSocket.isConnected
        #expect(isConnected)
    }
}
