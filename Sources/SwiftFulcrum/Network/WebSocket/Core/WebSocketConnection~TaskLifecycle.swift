// WebSocketConnection~TaskLifecycle.swift

import Foundation

extension WebSocketConnection {
    func updateURL(_ newURL: URL) { self.url = newURL }

    func createNewTask(with url: URL? = nil, receiverCancellation: ReceiverCancellation = .cancel) async {
        if let url { self.url = url }

        switch receiverCancellation {
        case .cancel:
            await cancelReceiverTask()
        case .preserve:
            break
        }
        if let task {
            lastCloseInformation = closeInformation
            await connectionEventTracker.stopTracking(taskIdentifier: task.taskIdentifier)
        }
        task?.cancel(with: .goingAway, reason: "Recreating task.".data(using: .utf8))
        task = session.webSocketTask(with: self.url)
        task?.maximumMessageSize = maximumMessageSize
        if let task {
            await connectionEventTracker.beginTracking(taskIdentifier: task.taskIdentifier)
        }
    }

    func cancelReceiverTask() async {
        receivedTask?.cancel()
        await receivedTask?.value
        receivedTask = nil
    }

    var closeInformation: (code: URLSessionWebSocketTask.CloseCode, reason: String?) {
        if let task {
            let code = task.closeCode
            let reason = task.swiftFulcrumCloseReasonSummary
            return (code, reason)
        }

        return lastCloseInformation
    }

    var connectionState: ConnectionState { get async { await connectionStateTracker.state } }

    func makeConnectionStateEvents() async -> AsyncStream<ConnectionState> {
        await connectionStateTracker.makeStream()
    }

    func updateConnectionState(_ newState: ConnectionState) async {
        await connectionStateTracker.update(to: newState)
    }

    func recordReconnectAttempt() { reconnectAttemptCount &+= 1 }

    func recordReconnectSuccess() { reconnectSuccessCount &+= 1 }

    var reconnectAttempts: Int { reconnectAttemptCount }

    var reconnectSuccesses: Int { reconnectSuccessCount }
}
