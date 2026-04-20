// WebSocketReconnectorValidator~AttemptPolicy.swift

import Foundation
import Testing
@testable import SwiftFulcrum

extension WebSocketReconnectorValidator {
    @Test("Reconnector exhaustion reports a concrete close reason", .timeLimit(.minutes(1)))
    func reportConcreteCloseReasonWhenAttemptsAreExhausted() async throws {
        let configuration = WebSocketConnection.Reconnector.Configuration(
            maximumReconnectionAttempts: 1,
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
            sleep: { duration in try await Task.sleep(for: duration) },
            jitter: { _ in 1 }
        )

        do {
            try await webSocket.reconnector.attemptReconnection(
                for: webSocket,
                shouldCancelReceiver: false,
                isInitialConnection: false
            )
            Issue.record("Reconnector should exhaust instead of succeeding")
        } catch let error as SwiftFulcrum.Client.Error {
            guard case .transport(.connectionClosed(let code, let reason)) = error else {
                Issue.record("Expected connectionClosed transport error, got \(error)")
                return
            }

            #expect(code == .goingAway)
            #expect(reason == "Reconnection attempts exhausted.")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }

        await webSocket.disconnect(with: "test teardown")
    }

    @Test("Reconnector cycles through full rotation before repeating candidates", .timeLimit(.minutes(1)))
    func cycleThroughFullRotationBeforeRepeat() async throws {
        let configuration = WebSocketConnection.Reconnector.Configuration(
            maximumReconnectionAttempts: 2,
            reconnectionDelay: 0.01,
            maximumDelay: 0.01,
            jitterRange: 1.0 ... 1.0
        )

        let current = URL(string: "wss://127.0.0.1:9")!
        let alternate = URL(string: "wss://127.0.0.1:10")!
        let injectedCatalog = [current, alternate]

        let webSocket = WebSocketConnection(
            url: current,
            configuration: .init(
                serverCatalogLoader: .makeConstant(injectedCatalog)
            ),
            reconnectConfiguration: configuration,
            connectionTimeout: 0.05,
            sleep: { duration in try await Task.sleep(for: duration) },
            jitter: { _ in 1 }
        )

        do {
            try await webSocket.reconnector.attemptReconnection(
                for: webSocket,
                with: nil,
                shouldCancelReceiver: false,
                isInitialConnection: false
            )
            Issue.record("Reconnection should exhaust attempts")
        } catch {
            let attempts = await webSocket.reconnector.attemptCount
            #expect(attempts == configuration.maximumReconnectionAttempts)
            #expect(await webSocket.url == current)
        }

        await webSocket.disconnect(with: "test teardown")
    }

    @Test("Reconnector exhausts after maximum attempts", .timeLimit(.minutes(1)))
    func exhaustAfterMaximumAttempts() async throws {
        let configuration = WebSocketConnection.Reconnector.Configuration(
            maximumReconnectionAttempts: 2,
            reconnectionDelay: 0.05,
            maximumDelay: 0.05,
            jitterRange: 1.0 ... 1.0
        )

        let injectedCatalog = [
            URL(string: "wss://127.0.0.1:9"),
            URL(string: "wss://127.0.0.1:10"),
            URL(string: "wss://127.0.0.1:11")
        ].compactMap { $0 }
        guard let current = injectedCatalog.first else {
            Issue.record("Injected catalog is empty")
            return
        }

        let webSocket = WebSocketConnection(
            url: current,
            configuration: .init(
                serverCatalogLoader: .makeConstant(injectedCatalog)
            ),
            reconnectConfiguration: configuration,
            connectionTimeout: 0.2,
            sleep: { duration in try await Task.sleep(for: duration) },
            jitter: { _ in 1 }
        )

        do {
            try await webSocket.reconnector.attemptReconnection(
                for: webSocket,
                with: nil,
                shouldCancelReceiver: false,
                isInitialConnection: false
            )
            Issue.record("Reconnection should exhaust attempts")
        } catch {
            let attempts = await webSocket.reconnector.attemptCount
            #expect(attempts == configuration.maximumReconnectionAttempts)
        }

        await webSocket.disconnect(with: "test teardown")
    }

    @Test("Reconnector stops after configured attempts with injected catalog", .timeLimit(.minutes(1)))
    func stopAfterConfiguredAttemptsWithInjectedCatalog() async throws {
        let configuration = WebSocketConnection.Reconnector.Configuration(
            maximumReconnectionAttempts: 2,
            reconnectionDelay: 0.01,
            maximumDelay: 0.01,
            jitterRange: 1.0 ... 1.0
        )

        let injectedCatalog = [
            URL(string: "wss://127.0.0.1:9"),
            URL(string: "wss://127.0.0.1:10"),
            URL(string: "wss://127.0.0.1:11")
        ].compactMap { $0 }

        guard let current = injectedCatalog.first else {
            Issue.record("Injected catalog is empty")
            return
        }

        let webSocket = WebSocketConnection(
            url: current,
            configuration: .init(
                serverCatalogLoader: .makeConstant(injectedCatalog)
            ),
            reconnectConfiguration: configuration,
            connectionTimeout: 0.05,
            sleep: { duration in try await Task.sleep(for: duration) },
            jitter: { _ in 1 }
        )

        do {
            try await webSocket.reconnector.attemptReconnection(
                for: webSocket,
                with: nil,
                shouldCancelReceiver: false,
                isInitialConnection: false
            )
            Issue.record("Reconnection should exhaust attempts")
        } catch {
            let attempts = await webSocket.reconnector.attemptCount
            #expect(attempts == configuration.maximumReconnectionAttempts)
        }

        await webSocket.disconnect(with: "test teardown")
    }

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
