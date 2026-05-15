// WebSocketConnectionValidator.swift

import Foundation
import Network
import Testing
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct WebSocketConnectionValidator {
    @Test("WebSocketConnection internal session preserves default timeout intervals", .timeLimit(.minutes(1)))
    func preserveDefaultTimeoutIntervals() async {
        let webSocket = WebSocketConnection(
            url: URL(string: "wss://example.invalid")!,
            connectionTimeout: 0.05
        )

        let session = await webSocket.session
        let configuration = session.configuration
        let defaultConfiguration = URLSessionConfiguration.default

        #expect(configuration.timeoutIntervalForRequest == defaultConfiguration.timeoutIntervalForRequest)
        #expect(configuration.timeoutIntervalForResource == defaultConfiguration.timeoutIntervalForResource)

        session.invalidateAndCancel()
    }

    @Test("WebSocketSessionDelegateProxy resolves tracked open events", .timeLimit(.minutes(1)))
    func resolveTrackedOpenEvents() async throws {
        let tracker = WebSocketConnectionEventTracker()
        let proxy = WebSocketSessionDelegateProxy(connectionEventTracker: tracker)
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }

        let task = session.webSocketTask(with: URL(string: "wss://example.invalid")!)
        await tracker.beginTracking(taskIdentifier: task.taskIdentifier)

        let waitTask = Task {
            try await tracker.waitForOpen(taskIdentifier: task.taskIdentifier)
        }

        proxy.urlSession(session, webSocketTask: task, didOpenWithProtocol: "fulcrum")
        try await waitTask.value
    }

    @Test("WebSocketSessionDelegateProxy resolves tracked completion failures", .timeLimit(.minutes(1)))
    func resolveTrackedCompletionFailures() async {
        let tracker = WebSocketConnectionEventTracker()
        let proxy = WebSocketSessionDelegateProxy(connectionEventTracker: tracker)
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }

        let task = session.webSocketTask(with: URL(string: "wss://example.invalid")!)
        let expectedError = URLError(.timedOut)
        await tracker.beginTracking(taskIdentifier: task.taskIdentifier)

        let waitTask = Task {
            try await tracker.waitForOpen(taskIdentifier: task.taskIdentifier)
        }

        proxy.urlSession(session, task: task, didCompleteWithError: expectedError)

        do {
            try await waitTask.value
            Issue.record("Expected tracked completion failure")
        } catch let error as SwiftFulcrum.Client.Error.Network {
            guard case .tlsNegotiationFailed(let forwardedError) = error else {
                Issue.record("Expected TLS negotiation failure, got \(error)")
                return
            }

            let forwardedURLError = try? #require(forwardedError as? URLError)
            #expect(forwardedURLError?.code == expectedError.code)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("WebSocketSessionDelegateProxy uses default challenge handling", .timeLimit(.minutes(1)))
    func useDefaultChallengeHandling() async {
        let tracker = WebSocketConnectionEventTracker()
        let proxy = WebSocketSessionDelegateProxy(connectionEventTracker: tracker)
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }

        let task = session.webSocketTask(with: URL(string: "wss://example.invalid")!)
        let challengeSender = ChallengeSenderStub()
        let protectionSpace = URLProtectionSpace(
            host: "example.invalid",
            port: 443,
            protocol: "https",
            realm: nil,
            authenticationMethod: NSURLAuthenticationMethodHTTPBasic
        )
        let challenge = URLAuthenticationChallenge(
            protectionSpace: protectionSpace,
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: challengeSender
        )

        let sessionChallengeResult = await withCheckedContinuation {
            (continuation: CheckedContinuation<(URLSession.AuthChallengeDisposition, String?), Never>) in
            proxy.urlSession(session, didReceive: challenge) { disposition, credential in
                continuation.resume(returning: (disposition, credential?.user))
            }
        }

        let taskChallengeResult = await withCheckedContinuation {
            (continuation: CheckedContinuation<(URLSession.AuthChallengeDisposition, String?), Never>) in
            proxy.urlSession(session, task: task, didReceive: challenge) { disposition, credential in
                continuation.resume(returning: (disposition, credential?.user))
            }
        }

        #expect(sessionChallengeResult.0 == URLSession.AuthChallengeDisposition.performDefaultHandling)
        #expect(sessionChallengeResult.1 == nil)
        #expect(taskChallengeResult.0 == URLSession.AuthChallengeDisposition.performDefaultHandling)
        #expect(taskChallengeResult.1 == nil)
    }

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

    @Test("connect timeout preserves the timeout close reason", .timeLimit(.minutes(1)))
    func connectTimeoutPreservesTimeoutCloseReason() async throws {
        let hangingServer = try LocalHangingTCPServer()
        let endpoint = try await hangingServer.start()
        defer {
            let server = hangingServer
            Task { await server.stop() }
        }

        let webSocket = WebSocketConnection(
            url: endpoint,
            connectionTimeout: 0.05
        )

        do {
            try await webSocket.connect(shouldAllowFailover: false)
            Issue.record("Expected connect() to fail when the socket never opens")
        } catch let error as SwiftFulcrum.Client.Error {
            guard case .transport(.connectionClosed(let code, let reason)) = error else {
                Issue.record("Expected connectionClosed timeout error, got \(error)")
                return
            }

            #expect(code == .goingAway)
            #expect(reason == "Connection timed out.")
        }

        let session = await webSocket.session
        session.invalidateAndCancel()
    }
}

private extension WebSocketConnectionValidator {
    func waitForCurrentTaskIdentifier(
        on webSocket: WebSocketConnection,
        timeout: Duration = .seconds(1)
    ) async throws -> Int {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while clock.now < deadline {
            if let taskIdentifier = await webSocket.task?.taskIdentifier {
                return taskIdentifier
            }
            try await Task.sleep(for: .milliseconds(10))
        }

        throw TimeoutError.missingSocketTask
    }

    func assertCancelledConnect(_ task: Task<Void, Swift.Error>) async {
        do {
            try await task.value
            Issue.record("Expected connect() task to terminate after explicit disconnect")
        } catch is CancellationError {
            return
        } catch let error as SwiftFulcrum.Client.Error {
            if case .transport(.connectionClosed(let code, let reason)) = error {
                #expect(code == .goingAway)
                #expect(reason == "test teardown")
                return
            }
            Issue.record("Unexpected SwiftFulcrum.Client.Error: \(error)")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

}
