// WebSocketValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension SwiftFulcrumNetworkValidators {
@Suite(.serialized, .tags(.network))
struct WebSocketValidator {
    @Test(
        "WebSocketModel connects and exchanges a unary request",
        .timeLimit(.minutes(1)),
        .enabled(if: TestExecutionPolicy.shouldRunNetwork, "Network tests are opt-in. Set SWIFTFULCRUM_RUN_NETWORK=1 to enable them.")
    )
    func connectAndExchangeUnaryRequest() async throws {
        let url = try await NetworkTestClient.pickServerURL()
        let webSocket = WebSocketModel(url: url)
        let stream = await webSocket.makeMessageStream()

        try await webSocket.connect()
        #expect(await webSocket.connectionState == .connected)

        let method: SwiftFulcrum.RPC.Method = .blockchain(.headers(.getTip))
        let request = method.createRequest(with: UUID())
        guard let data = request.data else {
            Issue.record("Failed to encode blockchain.headers.get_tip request")
            return
        }

        try await webSocket.send(data: data)

        var iterator = stream.makeAsyncIterator()
        var receivedTip: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip?
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

            if let payload, let decoded = try? payload.decode(SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self) {
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

    @Test(
        "WebSocketModel message stream ends after disconnect",
        .timeLimit(.minutes(1)),
        .enabled(if: TestExecutionPolicy.shouldRunNetwork, "Network tests are opt-in. Set SWIFTFULCRUM_RUN_NETWORK=1 to enable them.")
    )
    func terminateMessageStreamAfterDisconnect() async throws {
        let url = try await NetworkTestClient.pickServerURL()
        let webSocket = WebSocketModel(url: url)
        let stream = await webSocket.makeMessageStream()

        try await webSocket.connect()
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
