// WebSocketSessionDelegateProxy.swift

import Foundation

final class WebSocketSessionDelegateProxy: NSObject, URLSessionWebSocketDelegate {
    private let connectionEventTracker: WebSocketConnectionEventTracker

    init(connectionEventTracker: WebSocketConnectionEventTracker) {
        self.connectionEventTracker = connectionEventTracker
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        completionHandler(.performDefaultHandling, nil)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        completionHandler(.performDefaultHandling, nil)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        let trackedError = makeTrackedConnectionError(for: task, error: error)
        Task {
            await connectionEventTracker.recordFailure(
                taskIdentifier: task.taskIdentifier,
                error: trackedError
            )
        }

    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        Task {
            await connectionEventTracker.recordOpen(taskIdentifier: webSocketTask.taskIdentifier)
        }

    }

    private func makeTrackedConnectionError(
        for task: URLSessionTask,
        error: (any Error)?
    ) -> Swift.Error {
        if let error {
            return SwiftFulcrum.Client.Error.Network.tlsNegotiationFailed(error)
        }

        guard let webSocketTask = task as? URLSessionWebSocketTask else {
            return SwiftFulcrum.Client.Error.transport(.connectionClosed(.invalid, nil))
        }

        let reason = webSocketTask.swiftFulcrumCloseReasonSummary
        return SwiftFulcrum.Client.Error.transport(.connectionClosed(webSocketTask.closeCode, reason))
    }
}
