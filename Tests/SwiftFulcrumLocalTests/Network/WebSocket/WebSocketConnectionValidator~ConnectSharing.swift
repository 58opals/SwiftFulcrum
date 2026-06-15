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

        let firstConnectTask = Task { try await webSocket.connect(shouldAllowFailover: false) }
        let firstTaskIdentifier = try await waitForCurrentTaskIdentifier(on: webSocket)

        let secondConnectTask = Task { try await webSocket.connect(shouldAllowFailover: false) }
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

        let firstConnectTask = Task { try await webSocket.connect(shouldAllowFailover: false) }
        let firstTaskIdentifier = try await waitForCurrentTaskIdentifier(on: webSocket)

        let secondConnectTask = Task { try await webSocket.connect(shouldAllowFailover: false) }
        try await Task.sleep(for: .milliseconds(50))
        secondConnectTask.cancel()

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await secondConnectTask.value
                }
                group.addTask {
                    try await Task.sleep(for: .milliseconds(250))
                    throw TimeoutError.missingSocketTask
                }

                try await group.next()
                group.cancelAll()
            }
            Issue.record("Expected cancellation error")
        } catch is CancellationError {
            let currentTaskIdentifier = try await waitForCurrentTaskIdentifier(on: webSocket)
            #expect(currentTaskIdentifier == firstTaskIdentifier)
        }

        await webSocket.disconnect(with: "test teardown")
        await assertCancelledConnect(firstConnectTask)

        let session = await webSocket.session
        session.invalidateAndCancel()
    }
}
