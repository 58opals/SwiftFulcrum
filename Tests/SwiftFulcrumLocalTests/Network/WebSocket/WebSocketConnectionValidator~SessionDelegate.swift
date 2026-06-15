// WebSocketConnectionValidator~SessionDelegate.swift

import Foundation
import Network
import OpalDiagnostics
import Testing
@testable import SwiftFulcrum

extension WebSocketConnectionValidator {
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

    @Test("WebSocket close reason summaries redact raw bytes")
    func redactCloseReasonSummary() {
        let rawReason = "server-payload-001122aabbcc"
        let reason = URLSessionWebSocketTask.swiftFulcrumCloseReasonSummary(
            for: Data(rawReason.utf8)
        )

        #expect(reason == "WebSocket close reason redacted (\(rawReason.utf8.count) bytes).")
        #expect(reason?.contains(rawReason) == false)
        #expect(URLSessionWebSocketTask.swiftFulcrumCloseReasonSummary(for: nil) == nil)
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
}
