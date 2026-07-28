// WebSocketConnectionValidator~ConnectSharing.swift

import Foundation
import Network
import OpalDiagnostics
import Testing
@testable import SwiftFulcrum

extension WebSocketConnectionValidator {
    @Test("disconnect() preserves close information after clearing the task", .timeLimit(.minutes(1)))
    func disconnectPreservesCloseInformationAfterClearingTask() async {
        let webSocket = WebSocketConnection(url: URL(string: "wss://example.invalid")!)

        await webSocket.disconnect(with: "unit-test shutdown")

        let closeInformation = await webSocket.closeInformation
        #expect(closeInformation.code == .goingAway)
        #expect(closeInformation.reason == "unit-test shutdown")

        let session = await webSocket.session
        session.invalidateAndCancel()
    }

    @Test("Concurrent connect calls share one in-flight socket task", .timeLimit(.minutes(1)))
    func concurrentConnectCallsShareOneInflightSocketTask() async throws {
        let hangingServer = try LocalHangingTCPServer()
        let endpoint = try await hangingServer.start()
        defer {
            let server = hangingServer
            Task { await server.stop() }
        }

        let webSocket = WebSocketConnection(
            url: endpoint,
            connectionTimeout: 5
        )

        let firstConnectTask = Task { try await webSocket.connect(using: .initialWithoutFailover) }
        let firstTaskIdentifier = try await waitForCurrentTaskIdentifier(on: webSocket)

        let secondConnectTask = Task { try await webSocket.connect(using: .initialWithoutFailover) }
        try await Task.sleep(for: .milliseconds(50))

        let currentTaskIdentifier = try await waitForCurrentTaskIdentifier(on: webSocket)
        #expect(currentTaskIdentifier == firstTaskIdentifier)

        await webSocket.disconnect(with: "test teardown")

        await assertCancelledConnect(firstConnectTask)
        await assertCancelledConnect(secondConnectTask)

        let session = await webSocket.session
        session.invalidateAndCancel()
    }

    @Test("Cancelling a shared connect waiter terminates promptly", .timeLimit(.minutes(1)))
    func cancellingSharedConnectWaiterTerminatesPromptly() async throws {
        let hangingServer = try LocalHangingTCPServer()
        let endpoint = try await hangingServer.start()
        defer {
            let server = hangingServer
            Task { await server.stop() }
        }

        let webSocket = WebSocketConnection(
            url: endpoint,
            connectionTimeout: 5
        )

        let firstConnectTask = Task { try await webSocket.connect(using: .initialWithoutFailover) }
        let firstTaskIdentifier = try await waitForCurrentTaskIdentifier(on: webSocket)

        let secondConnectTask = Task { try await webSocket.connect(using: .initialWithoutFailover) }
        try await Task.sleep(for: .milliseconds(50))
        secondConnectTask.cancel()

        await expectCancelledConnectWaiter(secondConnectTask)
        let currentTaskIdentifier = try await waitForCurrentTaskIdentifier(on: webSocket)
        #expect(currentTaskIdentifier == firstTaskIdentifier)

        await webSocket.disconnect(with: "test teardown")
        await assertCancelledConnect(firstConnectTask)

        let session = await webSocket.session
        session.invalidateAndCancel()
    }

    @Test("Cancelling the final shared connect waiter cancels the socket attempt", .timeLimit(.minutes(1)))
    func cancelSocketAttemptWhenFinalSharedConnectWaiterCancels() async throws {
        let hangingServer = try LocalHangingTCPServer()
        let endpoint = try await hangingServer.start()
        let webSocket = WebSocketConnection(
            url: endpoint,
            connectionTimeout: 5
        )

        let firstConnectTask = Task {
            try await webSocket.connect(using: .initialWithoutFailover)
        }
        let firstTaskIdentifier = try await waitForCurrentTaskIdentifier(
            on: webSocket
        )
        let secondConnectTask = Task {
            try await webSocket.connect(using: .initialWithoutFailover)
        }

        let didRegisterBothWaiters = await waitUntil(timeout: .seconds(2)) {
            guard let generationIdentifier =
                    await webSocket.connectTaskGenerationIdentifier else {
                return false
            }
            return await webSocket
                .connectTaskWaiterCountsByGeneration[generationIdentifier] == 2
        }
        #expect(didRegisterBothWaiters)

        secondConnectTask.cancel()
        await expectCancelledConnectWaiter(secondConnectTask)
        #expect(
            try await waitForCurrentTaskIdentifier(on: webSocket)
                == firstTaskIdentifier
        )

        firstConnectTask.cancel()
        await expectCancelledConnectWaiter(firstConnectTask)
        let didCancelSocketAttempt = await waitUntil(timeout: .seconds(2)) {
            let connectionState = await webSocket.connectionState
            let socketTask = await webSocket.task
            let connectTask = await webSocket.connectTask
            return connectionState == .disconnected
                && socketTask == nil
                && connectTask == nil
        }
        #expect(didCancelSocketAttempt)

        await webSocket.disconnect(with: "test teardown")
        let session = await webSocket.session
        session.invalidateAndCancel()
        await hangingServer.stop()
    }

    @Test("Immediately cancelling a shared connect waiter terminates promptly", .timeLimit(.minutes(1)))
    func immediatelyCancellingSharedConnectWaiterTerminatesPromptly() async throws {
        let hangingServer = try LocalHangingTCPServer()
        let endpoint = try await hangingServer.start()
        defer {
            let server = hangingServer
            Task { await server.stop() }
        }

        let webSocket = WebSocketConnection(
            url: endpoint,
            connectionTimeout: 5
        )

        let firstConnectTask = Task { try await webSocket.connect(using: .initialWithoutFailover) }
        let firstTaskIdentifier = try await waitForCurrentTaskIdentifier(on: webSocket)

        let secondConnectTask = Task { try await webSocket.connect(using: .initialWithoutFailover) }
        secondConnectTask.cancel()

        await expectCancelledConnectWaiter(secondConnectTask)
        let currentTaskIdentifier = try await waitForCurrentTaskIdentifier(on: webSocket)
        #expect(currentTaskIdentifier == firstTaskIdentifier)

        await webSocket.disconnect(with: "test teardown")
        await assertCancelledConnect(firstConnectTask)

        let session = await webSocket.session
        session.invalidateAndCancel()
    }
}
