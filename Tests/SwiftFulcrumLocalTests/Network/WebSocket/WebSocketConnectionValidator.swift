// WebSocketConnectionValidator.swift

import Foundation
import Network
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

    @Test("disconnect() preserves close information after clearing the task", .timeLimit(.minutes(1)))
    func disconnectPreservesCloseInformationAfterClearingTask() async {
        let webSocket = WebSocketModel(url: URL(string: "wss://example.invalid")!)

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
        defer { hangingServer.stop() }

        let webSocket = WebSocketModel(
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
}

private extension WebSocketConnectionValidator {
    func waitForCurrentTaskIdentifier(
        on webSocket: WebSocketModel,
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

    enum TimeoutError: Swift.Error {
        case missingSocketTask
    }
}

private final class LocalHangingTCPServer: @unchecked Sendable {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "SwiftFulcrumLocalHangingTCPServer")
    private let lock = NSLock()
    private var connections: [NWConnection] = .init()
    private var startContinuation: CheckedContinuation<URL, Swift.Error>?

    init() throws {
        listener = try NWListener(using: .tcp, on: .any)
    }

    func start() async throws -> URL {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<URL, Swift.Error>) in
            lock.lock()
            startContinuation = continuation
            lock.unlock()

            listener.stateUpdateHandler = { [weak self] state in
                self?.handleStateUpdate(state)
            }

            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection)
            }

            listener.start(queue: queue)
        }
    }

    func stop() {
        lock.lock()
        let activeConnections = connections
        connections.removeAll(keepingCapacity: false)
        let continuation = startContinuation
        startContinuation = nil
        lock.unlock()

        for connection in activeConnections {
            connection.cancel()
        }
        continuation?.resume(throwing: CancellationError())
        listener.cancel()
    }

    private func handleStateUpdate(_ state: NWListener.State) {
        switch state {
        case .ready:
            guard let port = listener.port else { return }
            resolveStart(with: .success(URL(string: "ws://127.0.0.1:\(port.rawValue)")!))
        case .failed(let error):
            resolveStart(with: .failure(error))
        default:
            break
        }
    }

    private func accept(_ connection: NWConnection) {
        lock.lock()
        connections.append(connection)
        lock.unlock()
        connection.start(queue: queue)
    }

    private func resolveStart(with result: Result<URL, Swift.Error>) {
        lock.lock()
        let continuation = startContinuation
        startContinuation = nil
        lock.unlock()

        guard let continuation else { return }
        continuation.resume(with: result)
    }
}
