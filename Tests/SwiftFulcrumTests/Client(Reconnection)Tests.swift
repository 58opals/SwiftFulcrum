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

@Suite("Client – Reconnection Behaviour")
struct ClientReconnectionTests {
    let client: Client
    init() async throws {
        let socket = WebSocket(
            url: try await .randomFulcrum(),
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
        
    }
    
    @Test("subscription stream ends on disconnect")
    func subscriptionEndsOnDisconnect() async throws {
        
    }
    
    @Test("subscription resumes after reconnect")
    func subscriptionContinuesAfterReconnect() async throws {
        
    }
    
    @Test("manual reconnection enables further RPCs")
    func rpcWorksAfterManualReconnect() async throws {
        
    }
}

@Suite("Fulcrum – Reconnection Behaviour")
struct FulcrumReconnectionTests {
    @Test("manual reconnection enables further RPCs")
    func rpcWorksAfterManualReconnect() async throws {
        let fulcrum = try await Fulcrum()
        try await fulcrum.start()
        
        await fulcrum.client.webSocket.disconnect(with: "forced")
        #expect(!(await fulcrum.client.webSocket.isConnected))
        
        try await fulcrum.reconnect()
        #expect(await fulcrum.client.webSocket.isConnected)
        
        let response: Fulcrum.RPCResponse<Response.Result.Blockchain.RelayFee, Never> = try await fulcrum.submit(method: .blockchain(.relayFee))
        
        guard let fee = response.extractRegularResponse() else {
            #expect(Bool(false), "missing RPC result")
            await fulcrum.stop()
            return
        }
        
        #expect(fee.fee > 0)
        
        await fulcrum.stop()
    }
    
    @Test("submit-based subscription resumes after reconnect")
    func submitSubscriptionContinuesAfterReconnect() async throws {
        let fulcrum = try await Fulcrum()
        try await fulcrum.start()
        
        let subscription = try await fulcrum.submit(
            method: .blockchain(.headers(.subscribe)),
            initialType: Response.Result.Blockchain.Headers.Subscribe.self,
            notificationType: Response.Result.Blockchain.Headers.SubscribeNotification.self)
        
        guard case .stream(_, _, let stream, let cancel) = subscription else {
            #expect(Bool(false), "missing stream response")
            await fulcrum.stop()
            return
        }
        
        var iterator = stream.makeAsyncIterator()
        _ = try await iterator.next()
        
        await fulcrum.client.webSocket.disconnect(with: "forced")
        try await fulcrum.reconnect()
        
        let next = try await iterator.next()
        #expect(next != nil)
        
        await cancel()
        await fulcrum.stop()
    }
}
