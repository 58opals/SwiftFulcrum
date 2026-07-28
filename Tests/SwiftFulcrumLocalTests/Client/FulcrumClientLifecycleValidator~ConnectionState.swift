// FulcrumClientLifecycleValidator~ConnectionState.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("connection state stream publishes idle/connected/disconnected", .timeLimit(.minutes(1)))
    func publishConnectionStateLifecycle() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await SwiftFulcrum.Client(client: client)

        let stream = await fulcrum.makeConnectionStateStream()
        let collector = Task { await collectConnectionStates(from: stream, count: 2, timeout: .seconds(2)) }

        try await startAndNegotiate(fulcrum, transport: transport)
        await fulcrum.stop()

        let states = await collector.value
        let idleIndex = states.firstIndex(of: .idle)
        let connectedIndex = states.firstIndex(of: .connected)
        let disconnectedIndex = states.firstIndex(of: .disconnected)

        #expect(idleIndex == 0)
        #expect(connectedIndex != nil)
        #expect(await fulcrum.isRunning == false)
        if let idleIndex, let connectedIndex {
            #expect(idleIndex < connectedIndex)
        }
        if let connectedIndex, let disconnectedIndex {
            #expect(connectedIndex <= disconnectedIndex)
        }
    }

    @Test("connection state stream terminates on stop()", .timeLimit(.minutes(1)))
    func connectionStateStreamTerminatesWhenStopped() async throws {
        let (fulcrum, _) = try await makeStartedFulcrum()
        let stream = await fulcrum.makeConnectionStateStream()

        await fulcrum.stop()

        let terminated = await detectConnectionStateStreamTermination(
            stream,
            within: .seconds(1)
        )
        #expect(terminated)
    }

    @Test("abandoned Client releases its observation task and disconnects transport", .timeLimit(.minutes(1)))
    func releaseAbandonedClientAndDisconnectTransport() async throws {
        let transport = TransportTestActor()
        weak var abandonedClient: SwiftFulcrum.Client?
        var connectionStateStream: AsyncStream<SwiftFulcrum.Client.ConnectionState>?

        do {
            let networkClient = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
            let client = await SwiftFulcrum.Client(client: networkClient)
            abandonedClient = client
            connectionStateStream = await client.makeConnectionStateStream()
            await Task.yield()
        }

        let clock = ContinuousClock()
        let releaseDeadline = clock.now + .seconds(2)
        while abandonedClient != nil, clock.now < releaseDeadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(abandonedClient == nil)

        let stream = try #require(connectionStateStream)
        let didTerminateStream = await detectConnectionStateStreamTermination(
            stream,
            within: .seconds(1)
        )
        #expect(didTerminateStream)

        let didDisconnect = await waitUntil(timeout: .seconds(2)) {
            await transport.connectionState == .disconnected
        }
        #expect(didDisconnect)
    }
}
