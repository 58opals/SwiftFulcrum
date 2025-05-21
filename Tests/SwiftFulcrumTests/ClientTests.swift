import Testing
import Foundation
@testable import SwiftFulcrum

private extension URL {
    /// Any random main-net Fulcrum endpoint from bundled `servers.json`.
    static func randomFulcrum() throws -> URL {
        guard let url = try WebSocket.Server.getServerList().randomElement() else {
            throw Fulcrum.Error.transport(.setupFailed)
        }
        return url
    }
}

@Suite("Client – Lifecycle, RPC & Subscriptions")
struct ClientTests {
    let client: Client
    init() throws {
        let socket = WebSocket(url: try .randomFulcrum())
        self.client = Client(webSocket: socket)
    }
    
    @Test("start → stop happy-path")
    func startAndStop() async throws {
        try await client.start()
        #expect(await client.webSocket.isConnected)
        
        await client.stop()
        #expect(!(await client.webSocket.isConnected))
    }
    
    @Test("regular RPC – relayFee")
    func relayFee() async throws {
        try await client.start()
        
        let fee: Double = try await client.call(
            method: .blockchain(.relayFee)
        )
        print("Relay fee: \(fee)")
        #expect(fee > 0)
        
        await client.stop()
    }
    
    @Test("blockchain.headers.subscribe delivers an initial tip")
    func headerSubscription() async throws {
        try await client.start()
        
        let method = Method.blockchain(.headers(.subscribe))
        typealias Payload = Response.JSONRPC.Result.Blockchain.Headers.Subscribe
        
        let (initial, _) =
        try await client.subscribe(method: method)
        as (Payload, AsyncThrowingStream<Payload, Swift.Error>)
        
        switch initial {
        case .topHeader(let tip):
            print("Initial tip: \(tip)")
            #expect(tip.height > 0)
        case .newHeader(let batch):
            print("Initial batch: \(batch)")
            #expect(!batch.isEmpty)
        }
        
        await client.stop()
    }
}

@Suite("Client – Concurrency & Robustness")
struct ClientConcurrencyTests {
    let client: Client
    init() throws {
        let socket = WebSocket(url: try .randomFulcrum())
        self.client = Client(webSocket: socket)
    }
    
    @Test("three concurrent RPCs resolve independently")
    func concurrentRPCs() async throws {
        try await client.start()
        
        typealias Tip = Response.JSONRPC.Result.Blockchain.Headers.GetTip
        
        async let relayFee: Double = client.call(method: .blockchain(.relayFee))
        async let est1Blk: Double  = client.call(method: .blockchain(.estimateFee(numberOfBlocks: 1)))
        async let tip:    Tip      = client.call(method: .blockchain(.headers(.getTip)))
        
        let (fee, estimate, best) = try await (relayFee, est1Blk, tip)
        
        #expect(fee      > 0)
        #expect(estimate > 0)
        #expect(best.height > 0)
        
        await client.stop()
    }
    
    @Test("second subscription to same stream throws duplicateHandler")
    func duplicateSubscriptionIsRejected() async throws {
        try await client.start()
        let headersSub = Method.blockchain(.headers(.subscribe))
        typealias Payload = Response.JSONRPC.Result.Blockchain.Headers.Subscribe
        
        _ = try await client.subscribe(method: headersSub)
        as (Payload, AsyncThrowingStream<Payload, Swift.Error>)
        
        await #expect(throws: Fulcrum.Error.self) {
            _ = try await client.subscribe(method: headersSub)
            as (Payload, AsyncThrowingStream<Payload, Swift.Error>)
        }
        
        await client.stop()
    }
}
