import Foundation
import Testing
@testable import SwiftFulcrum

private enum TestError: Swift.Error {
    case general
    case urlNotFound
}

struct TestBed {
    @Test
    func connectAndProbe() async throws {
        let urls = try await WebSocket.Server.getServerList()
        guard let url = urls.randomElement() else { throw TestError.urlNotFound }
        let webSocket = WebSocket(
            url: url,
            reconnectConfiguration: .init(
                maximumReconnectionAttempts: 0,
                reconnectionDelay: 0.5,
                maximumDelay: 1,
                jitterRange: 1...1
            ),
            connectionTimeout: 5
        )
        
        let client = Client(webSocket: webSocket)
        #expect(await !client.webSocket.isConnected)
        #expect(await client.webSocket.isConnected == webSocket.isConnected)
        try await client.start()
        #expect(await client.webSocket.isConnected)
        #expect(await client.webSocket.isConnected == webSocket.isConnected)
        
        let (id, tip): (UUID, Response.Result.Blockchain.Headers.GetTip) = try await client.call(
            method: .blockchain(.headers(.getTip)),
            options: .init(timeout: .seconds(3))
        )
        
        print("\(id) - \(tip.height) [\(tip.hex)]")
        
        try await client.reconnect()
        #expect(await client.webSocket.isConnected)
        #expect(await client.webSocket.isConnected == webSocket.isConnected)
        
        await client.stop()
        #expect(await !client.webSocket.isConnected)
        #expect(await client.webSocket.isConnected == webSocket.isConnected)
    }
}
