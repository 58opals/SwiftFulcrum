// FulcrumClientLifecycleValidator~StartStopOrdering.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("start waits for in-flight stop before reconnecting", .timeLimit(.minutes(1)))
    func waitForInflightStopBeforeStartingAgain() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureDisconnectPaused(true)

        let stopTask = Task {
            await fulcrum.stop()
        }
        let didPauseStop = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingDisconnectCount() == 1
        }
        #expect(didPauseStop)

        let baselineOutgoingCount = await transport.sentMessages.count
        let startTask = Task {
            try await fulcrum.start()
        }
        try await Task.sleep(for: .milliseconds(100))
        #expect(await transport.sentMessages.count == baselineOutgoingCount)

        await transport.configureDisconnectPaused(false)
        await stopTask.value
        try await completeProtocolNegotiation(on: transport)
        try await startTask.value

        #expect(await fulcrum.isRunning)
        #expect(await transport.connectionState == .connected)

        await fulcrum.stop()
    }

    @Test("latest stop wins while start waits for teardown", .timeLimit(.minutes(1)))
    func preserveLatestStopWhileStartWaitsForTeardown() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let baselineOutgoingCount = await transport.sentMessages.count
        await transport.configureDisconnectPaused(true)

        let firstStopTask = Task {
            await fulcrum.stop()
        }
        let didPauseStop = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingDisconnectCount() == 1
        }
        #expect(didPauseStop)

        let startTask = Task {
            try await fulcrum.start()
        }
        try await Task.sleep(for: .milliseconds(100))

        let latestStopTask = Task {
            await fulcrum.stop()
        }
        try await Task.sleep(for: .milliseconds(100))

        await transport.configureDisconnectPaused(false)
        await firstStopTask.value
        await latestStopTask.value
        try await startTask.value

        #expect(await fulcrum.isRunning == false)
        #expect(await transport.connectionState == .disconnected)
        #expect(await transport.sentMessages.count == baselineOutgoingCount)
    }
}
