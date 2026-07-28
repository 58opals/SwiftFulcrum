// WebSocketConnectionValidator~ConnectCancellation.swift

import Foundation
import Testing
@testable import SwiftFulcrum

extension WebSocketConnectionValidator {
    @Test("replacement connect callers share a fresh generation", .timeLimit(.minutes(1)))
    func shareFreshConnectGenerationAcrossReplacementCallers() async throws {
        let hangingServer = try LocalHangingTCPServer()
        let endpoint = try await hangingServer.start()
        let webSocket = WebSocketConnection(
            url: endpoint,
            connectionTimeout: 5
        )
        var connectTasks = [Task<Void, Swift.Error>]()

        do {
            let firstConnectTask = Task {
                try await webSocket.connect(using: .initialWithoutFailover)
            }
            connectTasks.append(firstConnectTask)
            let firstSocketTaskIdentifier = try await waitForCurrentTaskIdentifier(on: webSocket)
            let firstGenerationIdentifier = try #require(
                await webSocket.connectTaskGenerationIdentifier
            )
            firstConnectTask.cancel()
            await expectCancelledConnectWaiter(firstConnectTask)

            let secondConnectTask = Task {
                try await webSocket.connect(using: .initialWithoutFailover)
            }
            connectTasks.append(secondConnectTask)
            let thirdConnectTask = Task {
                try await webSocket.connect(using: .initialWithoutFailover)
            }
            connectTasks.append(thirdConnectTask)

            let didShareFreshGeneration = await waitUntil(timeout: .seconds(2)) {
                guard let generationIdentifier = await webSocket.connectTaskGenerationIdentifier else {
                    return false
                }
                let socketTaskIdentifier = await webSocket.task?.taskIdentifier
                let waiterCount = await webSocket
                    .connectTaskWaiterCountsByGeneration[generationIdentifier]
                return generationIdentifier != firstGenerationIdentifier
                    && socketTaskIdentifier != nil
                    && socketTaskIdentifier != firstSocketTaskIdentifier
                    && waiterCount == 2
            }
            #expect(didShareFreshGeneration)

            await tearDownConnectCancellationTest(
                webSocket: webSocket,
                hangingServer: hangingServer,
                connectTasks: connectTasks
            )
            await assertCancelledConnect(secondConnectTask)
            await assertCancelledConnect(thirdConnectTask)
        } catch {
            await tearDownConnectCancellationTest(
                webSocket: webSocket,
                hangingServer: hangingServer,
                connectTasks: connectTasks
            )
            throw error
        }
    }

    @Test("cancelling the sole connect caller leaves no orphaned failover", .timeLimit(.minutes(1)))
    func cancelSoleConnectCallerWithoutLeavingOrphanedFailover() async throws {
        let hangingServer = try LocalHangingTCPServer()
        let endpoint = try await hangingServer.start()
        let webSocket = WebSocketConnection(
            url: endpoint,
            configuration: .init(
                bootstrapServers: [endpoint],
                serverCatalogLoader: .makeConstant([endpoint])
            ),
            reconnectConfiguration: .init(
                maximumReconnectionAttempts: 0,
                reconnectionDelay: 0,
                maximumDelay: 0,
                jitterRange: 1 ... 1
            ),
            connectionTimeout: 0.02
        )
        var connectTasks = [Task<Void, Swift.Error>]()

        do {
            let firstConnectTask = Task { try await webSocket.connect() }
            connectTasks.append(firstConnectTask)
            let didEnterFailover = await waitUntil(timeout: .seconds(2)) {
                await webSocket.reconnectAttempts > 0
            }
            #expect(didEnterFailover)

            let firstSocketTaskIdentifier = try await waitForCurrentTaskIdentifier(on: webSocket)
            firstConnectTask.cancel()
            await expectCancelledConnectWaiter(firstConnectTask)
            let didFinishCancelledGeneration = await waitUntil(timeout: .seconds(2)) {
                let connectionState = await webSocket.connectionState
                let task = await webSocket.task
                return connectionState == .disconnected && task == nil
            }
            #expect(didFinishCancelledGeneration)

            let attemptsAfterCancellation = await webSocket.reconnectAttempts
            let secondConnectTask = Task { try await webSocket.connect() }
            connectTasks.append(secondConnectTask)
            let didStartIndependentAttempt = await waitUntil(timeout: .seconds(2)) {
                let reconnectAttempts = await webSocket.reconnectAttempts
                let socketTaskIdentifier = await webSocket.task?.taskIdentifier
                return reconnectAttempts > attemptsAfterCancellation
                    && socketTaskIdentifier != nil
                    && socketTaskIdentifier != firstSocketTaskIdentifier
            }
            #expect(didStartIndependentAttempt)

            await tearDownConnectCancellationTest(
                webSocket: webSocket,
                hangingServer: hangingServer,
                connectTasks: connectTasks
            )
            await assertCancelledConnect(secondConnectTask)
            let didClearConnectState = await waitUntil(timeout: .seconds(2)) {
                let connectTask = await webSocket.connectTask
                let socketTask = await webSocket.task
                return connectTask == nil && socketTask == nil
            }
            #expect(didClearConnectState)
        } catch {
            await tearDownConnectCancellationTest(
                webSocket: webSocket,
                hangingServer: hangingServer,
                connectTasks: connectTasks
            )
            throw error
        }
    }

    private func tearDownConnectCancellationTest(
        webSocket: WebSocketConnection,
        hangingServer: LocalHangingTCPServer,
        connectTasks: [Task<Void, Swift.Error>]
    ) async {
        for connectTask in connectTasks {
            connectTask.cancel()
        }
        await webSocket.disconnect(with: "test teardown")
        let session = await webSocket.session
        session.invalidateAndCancel()
        await hangingServer.stop()
        for connectTask in connectTasks {
            _ = try? await awaitConnectTask(
                connectTask,
                timeout: .milliseconds(250)
            )
        }
    }
}
