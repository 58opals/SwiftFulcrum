// FulcrumClientLifecycleValidator~NetworkCancellation.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("stop interrupts an unlimited hanging startup", .timeLimit(.minutes(1)))
    func interruptUnlimitedHangingStartupByStopping() async throws {
        let hangingServer = try WebSocketConnectionValidator.LocalHangingTCPServer()
        let endpoint = try await hangingServer.start()
        let webSocket = WebSocketConnection(
            url: endpoint,
            reconnectConfiguration: .init(
                maximumReconnectionAttempts: 0,
                reconnectionDelay: 0,
                maximumDelay: 0,
                jitterRange: 1 ... 1
            ),
            connectionTimeout: 0.05
        )
        let client = FulcrumNetworkClient(
            transport: WebSocketTransport(webSocket: webSocket),
            protocolNegotiation: .init()
        )
        let startCompletion = ReconnectCompletionState()
        let startTask = Task {
            do {
                try await client.start()
                await startCompletion.markCompleted()
            } catch {
                await startCompletion.markCompleted()
                throw error
            }
        }

        let didEnterUnlimitedFailover = await waitUntil(timeout: .seconds(2)) {
            await webSocket.reconnectAttempts > 0
        }
        #expect(didEnterUnlimitedFailover)
        let completedBeforeStop = await waitUntil(timeout: .milliseconds(150)) {
            await startCompletion.isCompleted
        }
        #expect(completedBeforeStop == false)

        let stopCompletion = ReconnectCompletionState()
        let stopTask = Task {
            await client.stop()
            await stopCompletion.markCompleted()
        }
        let didStop = await waitUntil(timeout: .seconds(2)) {
            await stopCompletion.isCompleted
        }
        #expect(didStop)

        if didStop {
            await stopTask.value
            await #expect(throws: (any Swift.Error).self) {
                try await startTask.value
            }
        } else {
            stopTask.cancel()
            startTask.cancel()
        }
        #expect(await webSocket.connectionState == .disconnected)
        #expect(await webSocket.task == nil)
        #expect(await webSocket.connectTask == nil)

        let session = await webSocket.session
        session.invalidateAndCancel()
        await hangingServer.stop()
    }

    @Test("caller cancellation waits for reconnect cleanup", .timeLimit(.minutes(1)))
    func waitForReconnectCleanupAfterCallerCancellation() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendPaused(true)

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

        let didPauseNegotiationSend = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(didPauseNegotiationSend)

        reconnectTask.cancel()
        await transport.configureOutgoingSendPaused(false)

        let didFinishCleanup = await waitUntil(timeout: .seconds(2)) {
            await reconnectCompletion.isCompleted
        }
        #expect(didFinishCleanup)
        if didFinishCleanup {
            #expect(await reconnectTask.value)
        }
        #expect(await transport.connectionState == .disconnected)

        await fulcrum.stop()
    }
}
