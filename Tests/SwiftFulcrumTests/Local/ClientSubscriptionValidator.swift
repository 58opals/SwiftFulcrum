import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientSubscriptionValidator {
    private static let initialHeight: UInt = 900_000
    private static let nextHeight: UInt = 900_001
    private static let initialHeaderHex = String(repeating: "a", count: 160)
    private static let nextHeaderHex = String(repeating: "b", count: 160)

    @Test("FulcrumNetworkClient decodes header subscription notifications without live mining", .timeLimit(.minutes(1)))
    func subscribeAndDecodeHeaderNotificationsWithoutLiveMining() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())

        let startTask = Task { try await client.start() }

        let versionRequest = await transport.dequeueOutgoing()
        let versionRequestObject = try TransportTestActor.decodeJSONObject(from: versionRequest)
        guard let versionIdentifier = versionRequestObject["id"] as? String else {
            Issue.record("Version request is missing an identifier")
            startTask.cancel()
            await client.stop()
            return
        }
        #expect(versionRequestObject["method"] as? String == "server.version")

        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = await transport.dequeueOutgoing()
        let featuresRequestObject = try TransportTestActor.decodeJSONObject(from: featuresRequest)
        guard let featuresIdentifier = featuresRequestObject["id"] as? String else {
            Issue.record("Features request is missing an identifier")
            startTask.cancel()
            await client.stop()
            return
        }
        #expect(featuresRequestObject["method"] as? String == "server.features")

        let featuresPayload = try TransportTestActor.encodeResponsePayload(
            identifier: featuresIdentifier,
            result: [
                "genesis_hash": "0000000000000000000000000000000000000000000000000000000000000000",
                "hash_function": "sha256",
                "server_version": "SwiftFulcrum.Client 2.0",
                "protocol_max": "1.6.0",
                "protocol_min": "1.4.0"
            ]
        )
        await transport.enqueueIncoming(.data(featuresPayload))

        try await startTask.value
        #expect(await client.connectionState == .connected)

        let cancellationToken = FulcrumNetworkClient.CallModel.Token()
        let subscribeTask = Task {
            try await client.subscribe(
                method: .blockchain(.headers(.subscribe)),
                options: .init(timeout: .seconds(30), token: cancellationToken)
            ) as (
                UUID,
                SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Headers.Subscribe,
                AsyncThrowingStream<SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Headers.SubscribeNotification, Swift.Error>
            )
        }

        let subscribeRequest = await transport.dequeueOutgoing()
        let subscribeRequestObject = try TransportTestActor.decodeJSONObject(from: subscribeRequest)
        guard let subscribeIdentifier = subscribeRequestObject["id"] as? String else {
            Issue.record("SubscribeModel request is missing an identifier")
            subscribeTask.cancel()
            await cancellationToken.cancel()
            await client.stop()
            return
        }
        #expect(subscribeRequestObject["method"] as? String == SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path)

        let initialPayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: [
                "height": Self.initialHeight,
                "hex": Self.initialHeaderHex
            ]
        )
        await transport.enqueueIncoming(.data(initialPayload))

        let (_, initial, updates) = try await subscribeTask.value
        #expect(initial.height == Self.initialHeight)
        #expect(initial.hex == Self.initialHeaderHex)

        let notificationPayload = try TransportTestActor.encodeSubscriptionNotification(
            method: SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path,
            parameters: [[
                "height": Self.nextHeight,
                "hex": Self.nextHeaderHex
            ]]
        )
        await transport.enqueueIncoming(.data(notificationPayload))

        var observedUpdateCount = 0
        for try await update in updates {
            #expect(update.subscriptionIdentifier == SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path)
            #expect(update.blocks.count == 1)
            guard let block = update.blocks.first else {
                Issue.record("Expected exactly one block in header notification")
                break
            }
            #expect(block.height == Self.nextHeight)
            #expect(block.hex == Self.nextHeaderHex)
            observedUpdateCount += 1
            break
        }
        #expect(observedUpdateCount == 1)

        await cancellationToken.cancel()

        let terminated = await NetworkTestClient.detectStreamTermination(
            updates,
            within: .seconds(10)
        )
        #expect(terminated)

        await client.stop()
        #expect(await client.connectionState == .disconnected)
    }
}
