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

@Suite("Client – Reconnection Behaviour")
struct ClientReconnectionTests {
    let client: Client
    init() throws {
        let socket = WebSocket(
            url: try .randomFulcrum(),
            reconnectConfiguration: .init(
                maximumReconnectionAttempts: 2,
                reconnectionDelay: 0.05,
                maximumDelay: 0.1,
                jitterRange: 1.0 ... 1.0
            )
        )
        self.client = Client(webSocket: socket)
    }
    
    @Test("RPC call terminates when socket disconnects")
    func rpcCallFailsOnDisconnect() async throws {
        try await client.start()
        
        let task = Task { () -> Double in
            try await client.call(method: .blockchain(.relayFee))
        }
        
        await client.webSocket.disconnect(with: "forced")
        
        do {
            _ = try await task.value
            #expect(Bool(false), "call unexpectedly succeeded")
        } catch {
            if case Fulcrum.Error.transport(.connectionClosed(_, _)) = error {
                #expect(true)
            } else {
                #expect(Bool(false), "unexpected error: \(error)")
            }
        }
        
        await client.stop()
    }
    
    @Test("subscription stream ends on disconnect")
    func subscriptionEndsOnDisconnect() async throws {
        try await client.start()
        
        let method = Method.blockchain(.headers(.subscribe))
        typealias Payload = Response.JSONRPC.Result.Blockchain.Headers.Subscribe
        let (_, _, stream) = try await client.subscribe(method: method) as (UUID, Payload, AsyncThrowingStream<Payload, Swift.Error>)
        
        var iterator = stream.makeAsyncIterator()
        
        await client.webSocket.disconnect(with: "forced")
        
        do {
            _ = try await iterator.next()
            #expect(Bool(false), "stream yielded unexpectedly")
        } catch {
            if case Fulcrum.Error.transport(.connectionClosed(_, _)) = error {
                #expect(true)
            } else {
                #expect(Bool(false), "unexpected error: \(error)")
            }
        }
        
        await client.stop()
    }
    
    @Test("subscription resumes after reconnect")
    func subscriptionContinuesAfterReconnect() async throws {
        try await client.start()
        
        let method = Method.blockchain(.headers(.subscribe))
        typealias Payload = Response.JSONRPC.Result.Blockchain.Headers.Subscribe
        let (_, _, stream) = try await client.subscribe(method: method) as (UUID, Payload, AsyncThrowingStream<Payload, Swift.Error>)
        
        var iterator = stream.makeAsyncIterator()
        _ = try await iterator.next()
        
        await client.webSocket.disconnect(with: "forced")
        try await client.reconnect()
        
        let next = try await iterator.next()
        #expect(next != nil)
        
        await client.stop()
    }
    
    @Test("manual reconnection enables further RPCs")
    func rpcWorksAfterManualReconnect() async throws {
        try await client.start()
        
        await client.webSocket.disconnect(with: "forced")
        #expect(!(await client.webSocket.isConnected))
        
        try await client.reconnect()
        #expect(await client.webSocket.isConnected)
        
        let fee: Double = try await client.call(method: .blockchain(.relayFee))
        #expect(fee > 0)
        
        await client.stop()
    }
}
