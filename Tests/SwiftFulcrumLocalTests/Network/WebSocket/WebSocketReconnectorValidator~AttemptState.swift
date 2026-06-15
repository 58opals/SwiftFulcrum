// WebSocketReconnectorValidator~AttemptState.swift

import Foundation
import Testing
@testable import SwiftFulcrum

extension WebSocketReconnectorValidator {
    @Test("Reconnector keeps reconnecting state between failed candidates", .timeLimit(.minutes(1)))
    func keepReconnectingStateBetweenFailedCandidates() async throws {
        let box = WebSocketBox()
        let probe = ReconnectStateProbe()

        let configuration = WebSocketConnection.Reconnector.Configuration(
            maximumReconnectionAttempts: 2,
            reconnectionDelay: 0.01,
            maximumDelay: 0.01,
            jitterRange: 1.0 ... 1.0
        )

        let injectedCatalog = [
            URL(string: "wss://127.0.0.1:9"),
            URL(string: "wss://127.0.0.1:10")
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
            connectionTimeout: 0.01,
            sleep: { duration in
                if let state = await box.makeConnectionState() {
                    await probe.record(state)
                }
                try await Task.sleep(for: duration)
            },
            jitter: { _ in 1 }
        )
        await box.store(webSocket)
        await webSocket.updateConnectionState(.reconnecting)

        do {
            try await webSocket.reconnector.attemptReconnection(
                for: webSocket,
                with: nil,
                shouldCancelReceiver: false,
                isInitialConnection: false
            )
            Issue.record("Reconnection should exhaust attempts")
        } catch {
            let states = await probe.read()
            #expect(states == [.reconnecting])
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
}
