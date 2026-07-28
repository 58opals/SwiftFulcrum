// FulcrumClientLifecycleValidator~ReconnectCallerCancellation.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("cancelling one reconnect waiter preserves shared recovery", .timeLimit(.minutes(1)))
    func preserveSharedReconnectAfterCancellingOneWaiter() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client
        await transport.configureOutgoingSendPaused(true)

        let firstReconnectTask = Task {
            try await fulcrum.reconnect()
        }
        let secondReconnectTask = Task {
            try await fulcrum.reconnect()
        }
        let didPauseNegotiation = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(didPauseNegotiation)
        let didRegisterBothWaiters = await waitUntil(timeout: .seconds(2)) {
            guard let generationIdentifier = await networkClient
                .reconnectTaskGenerationIdentifier else {
                return false
            }
            return await networkClient
                .reconnectTaskWaiterCountsByGeneration[generationIdentifier] == 2
        }
        #expect(didRegisterBothWaiters)

        firstReconnectTask.cancel()
        await #expect(throws: CancellationError.self) {
            try await firstReconnectTask.value
        }
        #expect(secondReconnectTask.isCancelled == false)

        await transport.configureOutgoingSendPaused(false)
        try await completeProtocolNegotiation(on: transport)
        try await secondReconnectTask.value

        #expect(await transport.makeReconnectAttempts() == 1)
        #expect(await fulcrum.isRunning)
        await fulcrum.stop()
    }

    @Test("caller cancellation interrupts an active subscription restore", .timeLimit(.minutes(1)))
    func interruptActiveSubscriptionRestoreByCancellingCaller() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscription = try await makeActiveHeadersSubscription(
            on: fulcrum,
            transport: transport
        )
        let reconnectCompletion = ReconnectCompletionState()
        let reconnectTask = Task {
            do {
                try await fulcrum.reconnect()
                await reconnectCompletion.markCompleted()
                return false
            } catch is CancellationError {
                await reconnectCompletion.markCompleted()
                return true
            } catch {
                Issue.record("Expected reconnect cancellation, got \(error)")
                await reconnectCompletion.markCompleted()
                return false
            }
        }

        try await completeProtocolNegotiation(on: transport)
        let restoreRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(
            restoreRequest["method"] as? String
                == SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path
        )
        let registeredRestoreRoute = await waitUntil(timeout: .seconds(2)) {
            await fulcrum.makeInflightUnaryCallCount() == 1
        }
        #expect(registeredRestoreRoute)

        reconnectTask.cancel()
        let completedCancellation = await waitUntil(timeout: .seconds(2)) {
            await reconnectCompletion.isCompleted
        }
        #expect(completedCancellation)
        if completedCancellation {
            #expect(await reconnectTask.value)
        }

        #expect(await fulcrum.makeInflightUnaryCallCount() == 0)
        #expect(await transport.connectionState == .disconnected)
        #expect(
            await NetworkTestClient.detectStreamTermination(
                subscription.updates,
                within: .seconds(2)
            )
        )

        await fulcrum.stop()
    }

    @Test("caller cancellation bypasses a shared pending cleanup", .timeLimit(.minutes(1)))
    func bypassSharedPendingCleanupByCancellingReconnectCaller() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        _ = try await makeActiveHeadersSubscription(
            on: fulcrum,
            transport: transport
        )
        let networkClient = await fulcrum.client
        let subscriptionKey = FulcrumNetworkClient.SubscriptionKey(
            methodPath: .headers,
            identifier: nil
        )
        let pendingCleanup = Task<Bool, Never> {
            try? await Task.sleep(for: .seconds(30))
            return false
        }
        await networkClient.recordSubscriptionCleanupTask(
            pendingCleanup,
            for: subscriptionKey
        )

        let reconnectCompletion = ReconnectCompletionState()
        let reconnectTask = Task {
            do {
                try await fulcrum.reconnect()
                await reconnectCompletion.markCompleted()
                return false
            } catch is CancellationError {
                await reconnectCompletion.markCompleted()
                return true
            } catch {
                Issue.record("Expected reconnect cancellation, got \(error)")
                await reconnectCompletion.markCompleted()
                return false
            }
        }

        try await completeProtocolNegotiation(on: transport)
        let completedBeforeCancellation = await waitUntil(timeout: .milliseconds(150)) {
            await reconnectCompletion.isCompleted
        }
        #expect(completedBeforeCancellation == false)

        reconnectTask.cancel()
        let completedCancellation = await waitUntil(timeout: .seconds(2)) {
            await reconnectCompletion.isCompleted
        }
        #expect(completedCancellation)
        if completedCancellation {
            #expect(await reconnectTask.value)
        }

        #expect(pendingCleanup.isCancelled == false)
        #expect(await transport.connectionState == .disconnected)
        #expect(await fulcrum.makeInflightUnaryCallCount() == 0)

        await fulcrum.stop()
        _ = await pendingCleanup.value
    }
}
