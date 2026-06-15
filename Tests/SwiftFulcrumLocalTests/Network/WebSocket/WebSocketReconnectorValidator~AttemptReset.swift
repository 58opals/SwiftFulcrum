// WebSocketReconnectorValidator~AttemptReset.swift

import Foundation
import Testing
@testable import SwiftFulcrum

extension WebSocketReconnectorValidator {
    @Test("Reconnector resets exhausted attempts for new sessions", .timeLimit(.minutes(1)))
    func resetExhaustedAttemptsForNewSessions() async throws {
        let counter = SleepCountActor()

        let configuration = WebSocketConnection.Reconnector.Configuration(
            maximumReconnectionAttempts: 2,
            reconnectionDelay: 0.01,
            maximumDelay: 0.01,
            jitterRange: 1.0 ... 1.0
        )

        let unreachable = URL(string: "wss://127.0.0.1:9")!
        let webSocket = WebSocketConnection(
            url: unreachable,
            configuration: .init(
                serverCatalogLoader: .makeConstant([unreachable])
            ),
            reconnectConfiguration: configuration,
            connectionTimeout: 0.01,
            sleep: { duration in
                await counter.increment()
                try await Task.sleep(for: duration)
            },
            jitter: { _ in 1 }
        )

        func exhaustReconnectionAttempts() async {
            do {
                try await webSocket.reconnector.attemptReconnection(
                    for: webSocket,
                    shouldCancelReceiver: false,
                    isInitialConnection: false
                )
                Issue.record("Reconnector should exhaust instead of succeeding")
            } catch {
                return
            }
        }

        await exhaustReconnectionAttempts()
        let firstSleepCount = await counter.read()
        #expect(firstSleepCount > 0)

        await counter.reset()
        await exhaustReconnectionAttempts()
        let secondSleepCount = await counter.read()
        #expect(secondSleepCount > 0)

        await webSocket.disconnect(with: "test teardown")
    }
}
