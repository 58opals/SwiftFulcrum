import Foundation
import Testing
@testable import SwiftFulcrum

@Suite(.tags(.network))
struct ClientWebSocketValidator {
    @Test("Client.start() relays unary responses over WebSocketModel", .timeLimit(.minutes(1)))
    func startClientAndReceiveUnaryResponses() async throws {
        let url = try await NetworkTestClient.pickRandomServerURL()
        let webSocket = WebSocketModel(url: url)
        let client = Client(
            transport: WebSocketTransportModel(webSocket: webSocket),
            protocolNegotiation: .init()
        )

        try await client.start()

        let (_, tip): (UUID, Response.ResultModel.BlockchainModel.HeadersModel.GetTipModel) = try await client.call(
            method: .blockchain(.headers(.getTip)),
            options: .init(timeout: .seconds(30))
        )

        #expect(tip.height > 0)
        #expect(await client.connectionState == .connected)

        await client.stop()
        #expect(await client.connectionState == .disconnected)
    }

    @Test("Client.stop() cancels active subscription streams", .timeLimit(.minutes(1)))
    func stopClientAndTerminateSubscriptions() async throws {
        let url = try await NetworkTestClient.pickRandomServerURL()
        let webSocket = WebSocketModel(url: url)
        let client = Client(
            transport: WebSocketTransportModel(webSocket: webSocket),
            protocolNegotiation: .init()
        )

        try await client.start()

        let (_, initial, updates): (
            UUID,
            Response.ResultModel.BlockchainModel.HeadersModel.SubscribeModel,
            AsyncThrowingStream<Response.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel, Swift.Error>
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
