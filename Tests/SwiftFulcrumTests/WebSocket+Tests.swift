import Foundation
import Testing
@testable import SwiftFulcrum

struct WebSocketTests {
    @Test("WebSocket connects and exchanges a unary request", .timeLimit(.minutes(1)))
    func connectAndExchangeUnaryRequest() async throws {
        let url = try await randomFulcrumURL()
        let webSocket = WebSocket(url: url)
        let stream = await webSocket.makeMessageStream()
        
        try await webSocket.connect()
        #expect(await webSocket.connectionState == .connected)
        
        let method: SwiftFulcrum.Method = .blockchain(.headers(.getTip))
        let request = method.createRequest(with: UUID())
        guard let data = request.data else {
            Issue.record("Failed to encode blockchain.headers.get_tip request")
            return
        }
        
        try await webSocket.send(data: data)
        
        var iterator = stream.makeAsyncIterator()
        var receivedTip: Response.Result.Blockchain.Headers.GetTip?
        while let message = try await iterator.next() {
            let payload: Data?
            switch message {
            case .data(let data):
                payload = data
            case .string(let string):
                payload = string.data(using: .utf8)
            @unknown default:
                payload = nil
            }
            
            if let payload, let decoded = try? payload.decode(Response.Result.Blockchain.Headers.GetTip.self) {
                receivedTip = decoded
                break
            }
        }
        
        guard let tip = receivedTip else {
            Issue.record("Did not receive a headers.get_tip response")
            return
        }
        
        #expect(tip.height > 0)
        #expect(tip.hex.count == 160)
        
        await webSocket.disconnect(with: "Test complete")
        #expect(await webSocket.connectionState == .disconnected)
    }
    
    @Test("WebSocket message stream ends after disconnect", .timeLimit(.minutes(1)))
    func messageStreamTerminatesAfterDisconnect() async throws {
        let url = URL(string: "wss://fulcrum-w7qr.onrender.com/ws")!
        let webSocket = WebSocket(url: url)
        let stream = await webSocket.makeMessageStream()
        
        try await webSocket.connect()
        await webSocket.disconnect(with: "message stream termination check")
        
        let terminated = await streamTerminates(stream, within: .seconds(10))
        #expect(terminated)
        #expect(await webSocket.connectionState == .disconnected)
    }
}
