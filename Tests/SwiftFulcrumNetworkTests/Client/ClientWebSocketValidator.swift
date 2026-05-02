// ClientWebSocketValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension SwiftFulcrumNetworkValidator {
@Suite(.serialized, .tags(.network))
struct ClientWebSocketValidator {
    @Test(
        "FulcrumNetworkClient.start() relays unary responses over WebSocketConnection",
        .timeLimit(.minutes(1)),
        .enabled(if: TestExecutionPolicy.shouldRunNetwork, "Network tests are opt-in. Set SWIFTFULCRUM_RUN_NETWORK=1 to enable them.")
    )
    func startClientAndReceiveUnaryResponses() async throws {
        let url = try await NetworkTestClient.pickServerURL()
        let webSocket = WebSocketConnection(url: url)
        let client = FulcrumNetworkClient(
            transport: WebSocketTransport(webSocket: webSocket),
            protocolNegotiation: .init()
        )

        try await client.start()

        let (_, tip): (UUID, SwiftFulcrum.Response.Blockchain.Headers.GetTip) = try await client.call(
            method: .blockchain(.headers(.getTip)),
            options: .init(timeout: .seconds(30))
        )

        #expect(tip.height > 0)
        #expect(await client.connectionState == .connected)

        await client.stop()
        #expect(await client.connectionState == .disconnected)
    }

    @Test(
        "FulcrumNetworkClient.stop() cancels active subscription streams",
        .timeLimit(.minutes(1)),
        .enabled(if: TestExecutionPolicy.shouldRunNetwork, "Network tests are opt-in. Set SWIFTFULCRUM_RUN_NETWORK=1 to enable them.")
    )
    func stopClientAndTerminateSubscriptions() async throws {
        let url = try await NetworkTestClient.pickServerURL()
        let webSocket = WebSocketConnection(url: url)
        let client = FulcrumNetworkClient(
            transport: WebSocketTransport(webSocket: webSocket),
            protocolNegotiation: .init()
        )

        try await client.start()

        let (_, initial, updates): (
            UUID,
            SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
            AsyncThrowingStream<SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification, Swift.Error>
        ) = try await client.subscribe(
            method: .blockchain(.headers(.subscribe)),
            options: .init(timeout: .seconds(30))
        )

        #expect(initial.height > 0)

        await client.stop()

        let terminated = await NetworkTestClient.detectStreamTermination(
            updates,
            within: .seconds(10)
        )
        #expect(terminated)
        #expect(await client.connectionState == .disconnected)
    }

}
}
