import Foundation
import Testing
@testable import SwiftFulcrum

struct TestBed {
    @Test
    func connectAndProbe() async throws {
        guard let url = try await WebSocket.Server.fetchServerList().randomElement() else { throw Fulcrum.Error.client(.urlNotFound) }
        print(url)
        
        let webSocket = WebSocket(url: url,
                                  configuration: .init(session: nil,
                                                       tlsDescriptor: nil,
                                                       metrics: nil,
                                                       logger: nil),
                                  reconnectConfiguration: .init(maximumReconnectionAttempts: 3,
                                                                reconnectionDelay: 1,
                                                                maximumDelay: 3,
                                                                jitterRange: 0.1 ... 0.5),
                                  connectionTimeout: 5)
        
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
