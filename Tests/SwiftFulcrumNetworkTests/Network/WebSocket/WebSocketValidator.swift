// WebSocketValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension SwiftFulcrumNetworkValidator {
@Suite(.serialized, .tags(.network))
struct WebSocketValidator {
    @Test(
        "WebSocketConnection connects and exchanges a unary request",
        .timeLimit(.minutes(1))
    )
    func connectAndExchangeUnaryRequest() async throws {
        let url = try await NetworkTestClient.pickServerURL()
        let webSocket = WebSocketConnection(url: url)
        let stream = await webSocket.makeMessageStream()

        do {
            try await webSocket.connect()
            #expect(await webSocket.connectionState == .connected)

            let method: SwiftFulcrum.RPC.Method = .blockchain(.headers(.getTip))
            let request = method.createRequest(with: UUID())
            let data = try #require(
                request.data,
                "Failed to encode blockchain.headers.get_tip request"
            )

            try await webSocket.send(data: data)

            var iterator = stream.makeAsyncIterator()
            var receivedTip: SwiftFulcrum.Response.Blockchain.Headers.Tip?
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

                if let payload,
                    let decoded = try? payload.decode(
                        SwiftFulcrum.Response.Blockchain.Headers.Tip.self
                    ) {
                    receivedTip = decoded
                    break
                }
            }

            let tip = try #require(
                receivedTip,
                "Did not receive a headers.get_tip response"
            )
            #expect(tip.height > 0)
            #expect(tip.hex.count == 160)
        } catch {
            await webSocket.disconnect(with: "Test failed")
            throw error
        }

        await webSocket.disconnect(with: "Test complete")
        #expect(await webSocket.connectionState == .disconnected)
    }

    @Test(
        "WebSocketConnection message stream ends after disconnect",
        .timeLimit(.minutes(1))
    )
    func terminateMessageStreamAfterDisconnect() async throws {
        let url = try await NetworkTestClient.pickServerURL()
        let webSocket = WebSocketConnection(url: url)
        let stream = await webSocket.makeMessageStream()

        do {
            try await webSocket.connect()
        } catch {
            await webSocket.disconnect(with: "Test failed")
            throw error
        }

        await webSocket.disconnect(with: "message stream termination check")

        let terminated = await NetworkTestClient.detectStreamTermination(
            stream,
            within: .seconds(10)
        )
        #expect(terminated)
        #expect(await webSocket.connectionState == .disconnected)
    }
}
}
