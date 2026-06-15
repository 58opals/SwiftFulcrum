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
}
