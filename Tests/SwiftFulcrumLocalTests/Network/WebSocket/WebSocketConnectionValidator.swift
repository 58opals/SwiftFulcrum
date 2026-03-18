import Foundation
import Testing
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct WebSocketConnectionValidator {
    @Test("WebSocketModel internal session preserves default timeout intervals", .timeLimit(.minutes(1)))
    func preserveDefaultTimeoutIntervals() async {
        let webSocket = WebSocketModel(
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
        let proxy = WebSocketSessionDelegateProxy(
            connectionEventTracker: tracker,
            baseDelegate: nil
        )
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
        let proxy = WebSocketSessionDelegateProxy(
            connectionEventTracker: tracker,
            baseDelegate: nil
        )
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

    @Test("WebSocketSessionDelegateProxy forwards delegate challenge and lifecycle callbacks", .timeLimit(.minutes(1)))
    func forwardDelegateChallengeAndLifecycleCallbacks() async {
        let tracker = WebSocketConnectionEventTracker()
        let recorder = SessionDelegateRecorder()
        let proxy = WebSocketSessionDelegateProxy(
            connectionEventTracker: tracker,
            baseDelegate: recorder
        )
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

        proxy.urlSession(session, webSocketTask: task, didOpenWithProtocol: "fulcrum")
        proxy.urlSession(
            session,
            webSocketTask: task,
            didCloseWith: .normalClosure,
            reason: "closed".data(using: .utf8)
        )

        #expect(sessionChallengeResult.0 == URLSession.AuthChallengeDisposition.performDefaultHandling)
        #expect(sessionChallengeResult.1 == nil)
        #expect(taskChallengeResult.0 == URLSession.AuthChallengeDisposition.useCredential)
        #expect(taskChallengeResult.1 == "swiftfulcrum")
        #expect(recorder.sessionChallengeCount == 1)
        #expect(recorder.taskChallengeCount == 1)
        #expect(recorder.openProtocols == ["fulcrum"])
        #expect(recorder.closeCodes == [.normalClosure])
        #expect(recorder.closeReasons == ["closed"])
    }
}

private final class SessionDelegateRecorder: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {
    private(set) var sessionChallengeCount = 0
    private(set) var taskChallengeCount = 0
    private(set) var openProtocols: [String?] = .init()
    private(set) var closeCodes: [URLSessionWebSocketTask.CloseCode] = .init()
    private(set) var closeReasons: [String?] = .init()

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        sessionChallengeCount += 1
        completionHandler(.performDefaultHandling, nil)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        taskChallengeCount += 1
        let credential = URLCredential(user: "swiftfulcrum", password: "secret", persistence: .none)
        completionHandler(.useCredential, credential)
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        openProtocols.append(`protocol`)
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        closeCodes.append(closeCode)
        closeReasons.append(reason.flatMap { String(data: $0, encoding: .utf8) })
    }
}

private final class ChallengeSenderStub: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
    func performDefaultHandling(for challenge: URLAuthenticationChallenge) {}
    func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {}
}
