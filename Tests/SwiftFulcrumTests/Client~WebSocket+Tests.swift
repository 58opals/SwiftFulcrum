import Foundation
import Testing
@testable import SwiftFulcrum

struct ClientWebSocketTests {
    @Test("Client.start() relays unary responses over WebSocket", .timeLimit(.minutes(1)))
    func startReceivesUnaryResponses() async throws {
        let url = try await randomFulcrumURL()
        let webSocket = WebSocket(url: url)
        let client = Client(
            transport: WebSocketTransport(webSocket: webSocket),
            protocolNegotiation: .init()
        )
        
        try await client.start()
        
        let (_, tip): (UUID, Response.Result.Blockchain.Headers.GetTip) = try await client.call(
            method: .blockchain(.headers(.getTip)),
            options: .init(timeout: .seconds(30))
        )
        
        #expect(tip.height > 0)
        #expect(await client.connectionState == .connected)
        
        await client.stop()
        #expect(await client.connectionState == .disconnected)
    }
    
    @Test("Client.stop() cancels active subscription streams", .timeLimit(.minutes(1)))
    func stopTerminatesSubscriptions() async throws {
        let url = try await randomFulcrumURL()
        let webSocket = WebSocket(url: url)
        let client = Client(
            transport: WebSocketTransport(webSocket: webSocket),
            protocolNegotiation: .init()
        )
        
        try await client.start()
        
        let (_, initial, updates): (UUID, Response.Result.Blockchain.Headers.Subscribe, AsyncThrowingStream<Response.Result.Blockchain.Headers.SubscribeNotification, Swift.Error>) =
        try await client.subscribe(
            method: .blockchain(.headers(.subscribe)),
            options: .init(timeout: .seconds(30))
        )
        
        #expect(initial.height > 0)
        
        await client.stop()
        
        let terminated = await streamTerminates(updates, within: .seconds(10))
        #expect(terminated)
        #expect(await client.connectionState == .disconnected)
    }
}
