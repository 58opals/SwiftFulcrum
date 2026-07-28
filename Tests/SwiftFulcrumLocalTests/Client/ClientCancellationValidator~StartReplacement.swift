// ClientCancellationValidator~StartReplacement.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientCancellationValidator {
    @Test(
        "cancelled waiter preserves shared startup generation",
        .timeLimit(.minutes(1))
    )
    func preserveSharedStartupGenerationAfterCancellingWaiter() async throws {
        let transport = TransportTestActor()
        await transport.configureConnectDelay(.seconds(5))
        let networkClient = FulcrumNetworkClient(
            transport: transport,
            protocolNegotiation: .init()
        )
        let fulcrum = await SwiftFulcrum.Client(client: networkClient)

        let ownerStartTask = Task {
            try await fulcrum.start()
        }
        let didCreateGeneration = await waitUntil(timeout: .seconds(2)) {
            await fulcrum.startTaskGenerationIdentifierForTesting != nil
        }
        #expect(didCreateGeneration)
        let generation = try #require(
            await fulcrum.startTaskGenerationIdentifierForTesting
        )

        let waiterStartTask = Task {
            try await fulcrum.start()
        }
        let didShareGeneration = await waitUntil(timeout: .seconds(2)) {
            await fulcrum.makeStartTaskWaiterCountForTesting(
                generationIdentifier: generation
            ) == 2
        }
        #expect(didShareGeneration)

        waiterStartTask.cancel()
        await #expect(throws: CancellationError.self) {
            try await waiterStartTask.value
        }

        #expect(
            await fulcrum.startTaskGenerationIdentifierForTesting
                == generation
        )
        #expect(
            await fulcrum.makeStartTaskWaiterCountForTesting(
                generationIdentifier: generation
            ) == 1
        )

        ownerStartTask.cancel()
        await #expect(throws: CancellationError.self) {
            try await ownerStartTask.value
        }
        #expect(await fulcrum.startTaskGenerationIdentifierForTesting == nil)
        await fulcrum.stop()
    }

    @Test(
        "stale startup completion preserves replacement generation",
        .timeLimit(.minutes(1))
    )
    func preserveReplacementGenerationAfterStaleStartupCompletion() async throws {
        let transport = TransportTestActor()
        await transport.configureOutgoingSendPaused(true)
        let networkClient = FulcrumNetworkClient(
            transport: transport,
            protocolNegotiation: .init()
        )
        let fulcrum = await SwiftFulcrum.Client(client: networkClient)

        let firstStartTask = Task {
            try await fulcrum.start()
        }
        let didPauseFirstStart = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(didPauseFirstStart)
        let firstGeneration = try #require(
            await fulcrum.startTaskGenerationIdentifierForTesting
        )

        firstStartTask.cancel()
        await #expect(throws: CancellationError.self) {
            try await firstStartTask.value
        }

        let replacementStartTask = Task {
            try await fulcrum.start()
        }
        let didCreateReplacement = await waitUntil(timeout: .seconds(2)) {
            guard let generation =
                    await fulcrum.startTaskGenerationIdentifierForTesting else {
                return false
            }
            return generation != firstGeneration
        }
        #expect(didCreateReplacement)
        let replacementGeneration = try #require(
            await fulcrum.startTaskGenerationIdentifierForTesting
        )

        await fulcrum.clearStartTaskIfCurrent(
            generationIdentifier: firstGeneration
        )
        #expect(
            await fulcrum.startTaskGenerationIdentifierForTesting
                == replacementGeneration
        )
        #expect(
            await fulcrum.makeStartTaskWaiterCountForTesting(
                generationIdentifier: replacementGeneration
            ) == 1
        )

        replacementStartTask.cancel()
        await #expect(throws: CancellationError.self) {
            try await replacementStartTask.value
        }
        #expect(await fulcrum.startTaskGenerationIdentifierForTesting == nil)

        await transport.configureOutgoingSendPaused(false)
        await fulcrum.stop()
    }

    @Test("replacement start waits for cancelled startup cleanup", .timeLimit(.minutes(1)))
    func waitForCancelledStartupCleanupBeforeReplacingStart() async throws {
        let transport = TransportTestActor()
        await transport.configureOutgoingSendPaused(true)
        let networkClient = FulcrumNetworkClient(
            transport: transport,
            protocolNegotiation: .init()
        )
        let fulcrum = await SwiftFulcrum.Client(client: networkClient)

        let cancelledStartTask = Task {
            try await fulcrum.start()
        }
        let didPauseNegotiation = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(didPauseNegotiation)

        cancelledStartTask.cancel()
        await #expect(throws: CancellationError.self) {
            try await cancelledStartTask.value
        }

        let replacementStartTask = Task {
            try await fulcrum.start()
        }
        try await Task.sleep(for: .milliseconds(100))
        #expect(await fulcrum.isRunning == false)
        #expect(await transport.sentMessages.isEmpty)

        await transport.configureOutgoingSendPaused(false)
        let didBeginReplacementNegotiation = await waitUntil(timeout: .seconds(2)) {
            await !transport.sentMessages.isEmpty
        }
        #expect(didBeginReplacementNegotiation)
        guard didBeginReplacementNegotiation else {
            replacementStartTask.cancel()
            await fulcrum.stop()
            return
        }
        try await completeProtocolNegotiation(on: transport)
        try await replacementStartTask.value

        #expect(await fulcrum.isRunning)
        #expect(await transport.connectionState == .connected)
        await fulcrum.stop()
    }
}
