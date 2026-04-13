// SessionDelegateRecorder.swift

import Foundation

final class SessionDelegateRecorder: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {
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
