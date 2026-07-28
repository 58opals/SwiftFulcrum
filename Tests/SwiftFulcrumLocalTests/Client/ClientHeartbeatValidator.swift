// ClientHeartbeatValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientHeartbeatValidator {
    @Test("Heartbeat timeout triggers reconnect attempt", .timeLimit(.minutes(1)))
    func heartbeatTimeoutTriggersReconnectAttempt() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(
            transport: transport,
            heartbeatInterval: .milliseconds(20),
            heartbeatTimeout: .milliseconds(20),
            protocolNegotiation: .init()
        )

        try await startAndNegotiate(client: client, transport: transport)
        try await Task.sleep(for: .milliseconds(120))

        let reconnectAttempts = await transport.makeReconnectAttempts()
        #expect(reconnectAttempts > 0)

        await client.stop()
    }

    @Test("Heartbeat reconnect failure fails inflight unary calls with heartbeat timeout", .timeLimit(.minutes(1)))
    func failInflightUnaryCallsWhenHeartbeatReconnectFails() async throws {
        let transport = TransportTestActor()
        await transport.configureReconnectFailure(SwiftFulcrum.Client.Error.transport(.reconnectFailed))

        let client = FulcrumNetworkClient(
            transport: transport,
            heartbeatInterval: .milliseconds(20),
            heartbeatTimeout: .milliseconds(20),
            protocolNegotiation: .init()
        )
        try await startAndNegotiate(client: client, transport: transport)

        let callTask = Task {
            do {
                let _: (UUID, SwiftFulcrum.Response.Blockchain.Headers.Tip) =
                    try await client.call(method: .blockchain(.headers(.getTip)))
                Issue.record("Expected inflight unary to fail when heartbeat reconnect fails")
            } catch let error as SwiftFulcrum.Client.Error {
                guard case .transport(.heartbeatTimeout) = error else {
                    Issue.record("Expected heartbeat timeout error, got \(error)")
                    return
                }
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        let request = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        #expect(request["method"] as? String == SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip)).path)

        await callTask.value
        let didAttemptReconnect = await waitUntil(timeout: .seconds(2)) {
            await transport.makeReconnectAttempts() > 0
        }
        #expect(didAttemptReconnect)

        await client.stop()
    }

    @Test("Heartbeat reconnect failure marks transport disconnected", .timeLimit(.minutes(1)))
    func heartbeatReconnectFailureMarksTransportDisconnected() async throws {
        let transport = TransportTestActor()
        await transport.configureReconnectFailure(SwiftFulcrum.Client.Error.transport(.reconnectFailed))

        let client = FulcrumNetworkClient(
            transport: transport,
            heartbeatInterval: .milliseconds(20),
            heartbeatTimeout: .milliseconds(20),
            protocolNegotiation: .init()
        )
        try await startAndNegotiate(client: client, transport: transport)

        let didAttemptReconnect = await waitUntil(timeout: .seconds(2)) {
            await transport.makeReconnectAttempts() > 0
        }
        #expect(didAttemptReconnect)

        let didDisconnect = await waitUntil(timeout: .milliseconds(250)) {
            await client.connectionState == .disconnected
        }
        #expect(didDisconnect)

        await client.stop()
    }

    @Test("Heartbeat reconnect failure terminates active subscriptions", .timeLimit(.minutes(1)))
    func failActiveSubscriptionsWhenHeartbeatReconnectFails() async throws {
        let transport = TransportTestActor()
        await transport.configureReconnectFailure(SwiftFulcrum.Client.Error.transport(.reconnectFailed))

        let client = FulcrumNetworkClient(
            transport: transport,
            heartbeatInterval: .milliseconds(20),
            heartbeatTimeout: .milliseconds(20),
            protocolNegotiation: .init()
        )
        try await startAndNegotiate(client: client, transport: transport)

        let subscribeTask = Task {
            try await client.subscribe(
                method: .blockchain(.headers(.subscribe))
            ) as (
                UUID,
                SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
                AsyncThrowingStream<SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification, Swift.Error>
            )
        }

        let subscribeRequest = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        #expect(subscribeRequest["method"] as? String == SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path)
        let subscribeIdentifier = try #require(subscribeRequest["id"] as? String)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 900_000, "hex": String(repeating: "a", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))

        let (_, _, updates) = try await subscribeTask.value

        let terminated = await NetworkTestClient.detectStreamTermination(
            updates,
            within: .milliseconds(250)
        )
        #expect(terminated)
        #expect(await client.makeActiveSubscriptionStates().isEmpty)
        #expect(await transport.makeReconnectAttempts() > 0)

        await client.stop()
    }

    @Test("stop() completes while heartbeat reconnect negotiation is waiting", .timeLimit(.minutes(1)))
    func stopCompletesWhileHeartbeatReconnectNegotiationIsWaiting() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(
            transport: transport,
            heartbeatInterval: .milliseconds(20),
            heartbeatTimeout: .milliseconds(20),
            protocolNegotiation: .init()
        )

        try await startAndNegotiate(client: client, transport: transport)

        let didBeginReconnectNegotiation = await waitUntil(timeout: .seconds(2)) {
            let versionCount = (try? await countSentMethodOccurrences("server.version", transport: transport)) ?? 0
            return versionCount >= 2
        }
        #expect(didBeginReconnectNegotiation)

        let completion = TaskCompletionState()
        let stopTask = Task {
            await client.stop()
            await completion.markCompleted()
        }

        let stopCompleted = await waitUntil(timeout: .milliseconds(250)) {
            await completion.isCompleted
        }

        if !stopCompleted {
            await client.resetNegotiatedSession()
        }

        #expect(stopCompleted)
        _ = await waitUntil(timeout: .seconds(2)) {
            await completion.isCompleted
        }
        _ = await stopTask.result
    }
}
