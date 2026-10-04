import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("Observed subscriptions stamp unchanged and changed restores before slow consumers read them",
        .timeLimit(.minutes(1)), arguments: RestoreStatusScenario.allCases)
    func observedSubscriptionUsesProducerGeneration(scenario: RestoreStatusScenario) async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let endpoint = SwiftFulcrum.API.blockchain.scriptHash.subscribe(scriptHash: String(repeating: "d", count: 64))
        let states = await fulcrum.makeConnectionRecoveryStream()
        let otherStates = await fulcrum.makeConnectionRecoveryStream()
        var iterator = states.makeAsyncIterator()
        let before = try #require(await iterator.next())
        #expect(before.state == .ready)
        let subscribe = Task { try await fulcrum.subscribeObserved(endpoint) }
        let request = try await decodeRequestObject(await transport.dequeueOutgoing())
        await transport.enqueueIncoming(.data(try TransportTestActor.encodeResponsePayload(
            identifier: extractRequestIdentifier(from: request), result: scenario.initial.map { $0 as Any } ?? NSNull())))
        let subscription = try await subscribe.value
        #expect(subscription.initial.value.status == scenario.initial)
        #expect(subscription.initial.generation == before.generation)
        let reconnect = Task { try await fulcrum.reconnect() }
        try await completeProtocolNegotiation(on: transport)
        let restore = try await decodeRequestObject(await transport.dequeueOutgoing())
        await transport.enqueueIncoming(.data(try TransportTestActor.encodeResponsePayload(
            identifier: extractRequestIdentifier(from: restore), result: scenario.restored.map { $0 as Any } ?? NSNull())))
        // Neither recovery stream nor the update stream has a reader during recovery.
        try await reconnect.value
        let recovering = try #require(await iterator.next())
        var ready = recovering
        while ready.state != .ready { ready = try #require(await iterator.next()) }
        #expect(ready.generation > before.generation)
        #expect(ready.sequence > recovering.sequence)
        await subscription.cancel()
        // Infer the endpoint's notification model through the iterator instead of its concrete type.
        var updates = subscription.updates.makeAsyncIterator()
        let value = try await updates.next()
        #expect(value?.value.status == scenario.restored)
        #expect(value?.generation == ready.generation)
        var otherIterator = otherStates.makeAsyncIterator()
        let otherBefore = try #require(await otherIterator.next())
        #expect(otherBefore == before)
        var otherReady = otherBefore
        while otherReady.state != .ready || otherReady.generation == before.generation {
            otherReady = try #require(await otherIterator.next())
        }
        #expect(otherReady == ready)
        await fulcrum.stop()
    }

    @Test("Recovery observation cancellation removes only that listener and retains an atomic current snapshot",
        .timeLimit(.minutes(1)))
    func recoveryObservationRegistrationAndCancellation() async throws {
        let transport = TransportTestActor()
        let network = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await SwiftFulcrum.Client(client: network)
        let first = await fulcrum.makeConnectionRecoveryStream()
        let second = await fulcrum.makeConnectionRecoveryStream()
        let consumer = Task { for await _ in first { } }
        consumer.cancel()
        await consumer.value
        for _ in 0..<1000 {
            if await network.recoveryObservationContinuations.count == 1 { break }
            await Task.yield()
        }
        #expect(await network.recoveryObservationContinuations.count == 1)
        try await startAndNegotiate(fulcrum, transport: transport)
        var secondIterator = second.makeAsyncIterator()
        #expect(await secondIterator.next()?.state == .unavailable)
        #expect(await secondIterator.next()?.state == .ready)
        let late = await fulcrum.makeConnectionRecoveryStream()
        var lateIterator = late.makeAsyncIterator()
        let snapshot = try #require(await lateIterator.next())
        #expect(snapshot.state == .ready)
        #expect(snapshot == (await network.recoveryObservation))
        await fulcrum.stop()
        let stopped = try #require(await lateIterator.next())
        #expect(stopped.generation > snapshot.generation)
    }
    @Test("A superseded early initial response reports reconnect interruption rather than caller cancellation", .timeLimit(.minutes(1)))
    func observedSetupSupersessionIsRetryable() async throws {
        let transport = TransportTestActor()
        let network = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await SwiftFulcrum.Client(client: network)
        try await startAndNegotiate(fulcrum, transport: transport)
        let endpoint = SwiftFulcrum.API.blockchain.scriptHash.subscribe(scriptHash: String(repeating: "e", count: 64))
        await transport.pauseNextSendCompletion(method: endpoint.method.path)
        let subscribe = Task { try await fulcrum.subscribeObserved(endpoint) }
        let initial = try await decodeRequestObject(await transport.dequeueOutgoing())
        await transport.enqueueIncoming(.data(try TransportTestActor.encodeResponsePayload(
            identifier: extractRequestIdentifier(from: initial), result: "initial")))
        let initialDelivered = await waitUntil(timeout: .seconds(5)) {
            await network.router.makeInflightUnaryCallCount() == 0
        }
        #expect(initialDelivered)
        let reconnect = Task { try await fulcrum.reconnect() }
        try await completeProtocolNegotiation(on: transport)
        let restore = try await decodeRequestObject(await transport.dequeueOutgoing())
        await transport.enqueueIncoming(.data(try TransportTestActor.encodeResponsePayload(
            identifier: extractRequestIdentifier(from: restore), result: "restored")))
        try await reconnect.value
        await transport.resumeSendCompletion()
        do {
            _ = try await subscribe.value
            Issue.record("Superseded initial response was accepted")
        } catch let error as SwiftFulcrum.Client.Error {
            #expect(error == .transport(.connectionClosed(.goingAway, "Connection superseded by reconnect.")))
        }
        let cleaned = await waitUntil(timeout: .seconds(5)) { await fulcrum.makeActiveSubscriptionStates().isEmpty }
        #expect(cleaned)
        await fulcrum.stop()
    }

}
