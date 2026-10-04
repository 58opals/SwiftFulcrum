// FulcrumClientLifecycleValidator~ReconnectSnapshots.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

enum RestoreStatusScenario: CaseIterable, Equatable, Sendable {
    case changed, cleared, firstActivity, unchanged

    var initial: String? {
        self == .firstActivity ? nil : "initial-status"
    }

    var restored: String? {
        switch self {
        case .changed, .firstActivity: "restored-status"
        case .cleared: nil
        case .unchanged: initial
        }
    }
}

enum StaleRestoreScenario: CaseIterable, Equatable, Sendable {
    case supersededEpoch, replacedStream, invalidatedAfterEpochCheck
}

extension FulcrumClientLifecycleValidator {
    @Test(
        "reconnect publishes the current script hash snapshot without a later notification",
        .timeLimit(.minutes(1)),
        arguments: RestoreStatusScenario.allCases
    )
    func reconnectPublishesCurrentScriptHashSnapshot(
        scenario: RestoreStatusScenario
    ) async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let scriptHash = String(repeating: "b", count: 64)
        let endpoint = SwiftFulcrum.API.blockchain.scriptHash.subscribe(scriptHash: scriptHash)
        let subscribeTask = Task {
            try await fulcrum.subscribe(endpoint, options: .init(timeout: .seconds(30)))
        }
        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
        let initialPayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: scenario.initial.map { $0 as Any } ?? NSNull()
        )
        await transport.enqueueIncoming(.data(initialPayload))
        let subscription = try await subscribeTask.value
        #expect(subscription.initial.status == scenario.initial)

        let reconnectTask = Task { try await fulcrum.reconnect() }
        try await completeProtocolNegotiation(on: transport)
        let restoreRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(restoreRequest["method"] as? String == endpoint.method.path)
        let restoreIdentifier = try extractRequestIdentifier(from: restoreRequest)
        let restorePayload = try TransportTestActor.encodeResponsePayload(
            identifier: restoreIdentifier,
            result: scenario.restored.map { $0 as Any } ?? NSNull()
        )
        await transport.enqueueIncoming(.data(restorePayload))
        try await reconnectTask.value

        // Cancellation ends the observation deterministically; buffered snapshots must still drain.
        await subscription.cancel()
        var statuses = [String?]()
        do {
            for try await update in subscription.updates {
                #expect(update.subscriptionIdentifier == scriptHash)
                statuses.append(update.status)
            }
        } catch let error as SwiftFulcrum.Client.Error {
            #expect(error == .client(.cancelled))
        }
        #expect(statuses == [scenario.restored])
        await fulcrum.stop()
    }

    @Test("restored snapshots precede subsequent wire notifications", .timeLimit(.minutes(1)))
    func restoredSnapshotsPrecedeSubsequentWireNotifications() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let scriptHash = String(repeating: "c", count: 64)
        let endpoint = SwiftFulcrum.API.blockchain.scriptHash.subscribe(scriptHash: scriptHash)
        let subscribeTask = Task {
            try await fulcrum.subscribe(endpoint, options: .init(timeout: .seconds(30)))
        }
        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
        await transport.enqueueIncoming(.data(try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: "initial-status"
        )))
        let subscription = try await subscribeTask.value

        let reconnectTask = Task { try await fulcrum.reconnect() }
        try await completeProtocolNegotiation(on: transport)
        let restoreRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let restoreIdentifier = try extractRequestIdentifier(from: restoreRequest)
        let restorePayload = try TransportTestActor.encodeResponsePayload(
            identifier: restoreIdentifier,
            result: "restored-status"
        )
        let notification = try TransportTestActor.encodeSubscriptionNotification(
            method: endpoint.method.path,
            parameters: [scriptHash, "newer-status"]
        )
        await transport.enqueueIncoming(.data(restorePayload))
        await transport.enqueueIncoming(.data(notification))
        try await reconnectTask.value

        // One iterator waits for both messages; their relative order is the observable contract.
        var statuses = [String?]()
        for try await update in subscription.updates {
            statuses.append(update.status)
            if statuses.count == 2 { break }
        }
        #expect(statuses == ["restored-status", "newer-status"])
        await subscription.cancel()
        await fulcrum.stop()
    }

    @Test(
        "stale restore snapshots do not reach a current or replacement stream",
        .timeLimit(.minutes(1)),
        arguments: StaleRestoreScenario.allCases
    )
    func staleRestoreSnapshotsDoNotReachCurrentOrReplacementStream(scenario: StaleRestoreScenario) async throws {
        let router = FulcrumNetworkClient.Router()
        let scriptHash = String(repeating: "d", count: 64)
        let key = FulcrumNetworkClient.SubscriptionKey(methodPath: .scriptHash, identifier: scriptHash)
        let registrationIdentifier = UUID()
        let restoreIdentifier = UUID()
        let generation = FulcrumNetworkClient.ConnectionRecoveryGeneration(1)
        let restore = FulcrumNetworkClient.SubscriptionRestoreContext(
            subscriptionKey: key,
            requestIdentifier: restoreIdentifier,
            streamRegistrationIdentifier: registrationIdentifier,
            reconnectSuccessCount: 1,
            recoveryGeneration: 1,
            recoveryGenerationAuthority: generation
        )
        let (originalStream, originalContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
        let (replacementStream, replacementContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
        let (_, acknowledgementContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
        try await router.addStream(
            key: key.string,
            continuation: originalContinuation,
            registrationIdentifier: registrationIdentifier,
            overflowError: nil,
            terminationAction: { _ in }
        )
        try await router.addUnary(
            id: restoreIdentifier,
            continuation: acknowledgementContinuation,
            subscriptionRestore: restore
        )
        let restorePayload = try TransportTestActor.encodeResponsePayload(
            identifier: restoreIdentifier.uuidString,
            result: "obsolete-status"
        )
        _ = await router.handle(raw: restorePayload) { _ in
            if scenario == .replacedStream {
                // Model cancellation and immediate same-key registration while the epoch check suspends.
                await router.cancel(identifier: .string(key.string))
                do {
                    try await router.addStream(
                        key: key.string,
                        continuation: replacementContinuation,
                        registrationIdentifier: UUID(),
                        overflowError: nil,
                        terminationAction: { _ in }
                    )
                } catch {
                    Issue.record("Replacement stream registration failed: \(error)")
                }
            }
            if scenario == .invalidatedAfterEpochCheck {
                // The async epoch check succeeded, but another recovery wins before publication.
                _ = generation.advance()
            }
            return scenario != .supersededEpoch
        }
        let notification = try TransportTestActor.encodeSubscriptionNotification(
            method: key.methodPath.rawValue,
            parameters: [scriptHash, "current-status"]
        )
        _ = await router.handle(raw: notification)
        await router.cancel(identifier: .string(key.string))
        let activeStream = scenario == .replacedStream ? replacementStream : originalStream
        var statuses = [String?]()
        for try await raw in activeStream {
            let update = try raw.decode(SwiftFulcrum.Response.Blockchain.ScriptHash.SubscribeNotification.self)
            statuses.append(update.status)
        }
        #expect(statuses == ["current-status"])
        #expect(await router.makeInflightUnaryCallCount() == 0)
    }
}
