import Foundation
import Testing
@testable import SwiftFulcrum

extension WebSocketReconnectorValidator {
    @Test("Reconnector exhausts after maximum attempts", .timeLimit(.minutes(1)))
    func exhaustAfterMaximumAttempts() async throws {
        let configuration = WebSocket.Reconnector.Configuration(
            maximumReconnectionAttempts: 2,
            reconnectionDelay: 0.05,
            maximumDelay: 0.05,
            jitterRange: 1.0 ... 1.0
        )

        let servers = try WebSocket.Server.decodeBundledServers(for: .mainnet)
        guard let current = servers.first else {
            Issue.record("Missing bundled servers for reconnection test")
            return
        }

        let unreachable = URL(string: "wss://127.0.0.1:9") ?? current
        let networkSession = URLSession(configuration: .ephemeral)
        defer { networkSession.invalidateAndCancel() }

        let webSocket = WebSocket(
            url: unreachable,
            configuration: .init(session: networkSession),
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
            let expected = max(configuration.maximumReconnectionAttempts, servers.count + 1)
            #expect(attempts == expected)
        }

        await webSocket.disconnect(with: "test teardown")
    }

    @Test("Reconnector stops after configured attempts with injected catalog", .timeLimit(.minutes(1)))
    func stopAfterConfiguredAttemptsWithInjectedCatalog() async throws {
        let configuration = WebSocket.Reconnector.Configuration(
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

        let networkSession = URLSession(configuration: .ephemeral)
        defer { networkSession.invalidateAndCancel() }

        let webSocket = WebSocket(
            url: current,
            configuration: .init(
                session: networkSession,
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

        let configuration = WebSocket.Reconnector.Configuration(
            maximumReconnectionAttempts: 2,
            reconnectionDelay: 0.01,
            maximumDelay: 0.01,
            jitterRange: 1.0 ... 1.0
        )

        let unreachable = URL(string: "wss://127.0.0.1:9")!
        let networkSession = URLSession(configuration: .ephemeral)
        defer { networkSession.invalidateAndCancel() }

        let webSocket = WebSocket(
            url: unreachable,
            configuration: .init(
                session: networkSession,
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
