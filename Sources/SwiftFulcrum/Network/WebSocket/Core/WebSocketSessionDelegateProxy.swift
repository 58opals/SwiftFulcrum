import Foundation

final class WebSocketSessionDelegateProxy: NSObject, URLSessionWebSocketDelegate {
    private let connectionEventTracker: WebSocketConnectionEventTracker
    private let baseDelegate: URLSessionDelegate?

    init(
        connectionEventTracker: WebSocketConnectionEventTracker,
        baseDelegate: URLSessionDelegate?
    ) {
        self.connectionEventTracker = connectionEventTracker
        self.baseDelegate = baseDelegate
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
        if baseDelegateResponds(
            to: #selector(URLSessionDelegate.urlSession(_:didBecomeInvalidWithError:))
        ),
           let delegate = baseDelegate {
            delegate.urlSession?(session, didBecomeInvalidWithError: error)
        }
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if baseDelegateResponds(
            to: #selector(URLSessionDelegate.urlSession(_:didReceive:completionHandler:))
        ),
           let delegate = baseDelegate {
            delegate.urlSession?(session, didReceive: challenge, completionHandler: completionHandler)
            return
        }

        completionHandler(.performDefaultHandling, nil)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if baseDelegateResponds(
            to: #selector(URLSessionTaskDelegate.urlSession(_:task:didReceive:completionHandler:))
        ),
           let delegate = baseDelegate as? URLSessionTaskDelegate {
            delegate.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler)
            return
        }

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

        if baseDelegateResponds(
            to: #selector(URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:))
        ),
           let delegate = baseDelegate as? URLSessionTaskDelegate {
            delegate.urlSession?(session, task: task, didCompleteWithError: error)
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

        if baseDelegateResponds(
            to: #selector(URLSessionWebSocketDelegate.urlSession(_:webSocketTask:didOpenWithProtocol:))
        ),
           let delegate = baseDelegate as? URLSessionWebSocketDelegate {
            delegate.urlSession?(session, webSocketTask: webSocketTask, didOpenWithProtocol: `protocol`)
        }
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        if baseDelegateResponds(
            to: #selector(URLSessionWebSocketDelegate.urlSession(_:webSocketTask:didCloseWith:reason:))
        ),
           let delegate = baseDelegate as? URLSessionWebSocketDelegate {
            delegate.urlSession?(session, webSocketTask: webSocketTask, didCloseWith: closeCode, reason: reason)
        }
    }

    private func baseDelegateResponds(to selector: Selector) -> Bool {
        guard let baseDelegate else { return false }
        return (baseDelegate as AnyObject).responds(to: selector)
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

        let reason = webSocketTask.closeReason.flatMap { String(data: $0, encoding: .utf8) }
        return SwiftFulcrum.Client.Error.transport(.connectionClosed(webSocketTask.closeCode, reason))
    }
}
