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

@Suite("Client – Lifecycle, RPC & Subscriptions")
struct ClientTests {
    let client: Client
    init() async throws {
        let socket = WebSocket(url: try await .randomFulcrum())
        self.client = Client(webSocket: socket)
    }
    
    @Test("start → stop happy-path")
    func startAndStop() async throws {
        try await client.start()
        #expect(await client.webSocket.isConnected)
        
        await client.stop()
        #expect(!(await client.webSocket.isConnected))
    }
    
    @Test("calling start twice has no effect")
    func startIsIdempotent() async throws {
        try await client.start()
        try await client.start()
        
        #expect(await client.webSocket.isConnected)
        
        await client.stop()
    }
    
    @Test("regular RPC – relayFee")
    func relayFee() async throws {
        try await client.start()
        
        let (id, fee): (UUID, Response.Result.Blockchain.RelayFee) = try await client.call(
            method: .blockchain(.relayFee)
        )
        print("Relay fee: \(fee.fee) [id: \(id)]")
        #expect(fee.fee > 0)
        
        await client.stop()
    }
    
    @Test("blockchain.headers.subscribe delivers an initial tip")
    func headerSubscription() async throws {
        
    }
}

@Suite("Client – Concurrency & Robustness")
struct ClientConcurrencyTests {
    let client: Client
    init() async throws {
        let socket = WebSocket(url: try await .randomFulcrum())
        self.client = Client(webSocket: socket)
    }
    
    @Test("three concurrent RPCs resolve independently")
    func concurrentRPCs() async throws {
        
    }
    
    @Test("second subscription to same stream throws duplicateHandler")
    func duplicateSubscriptionIsRejected() async throws {
        
    }
}
