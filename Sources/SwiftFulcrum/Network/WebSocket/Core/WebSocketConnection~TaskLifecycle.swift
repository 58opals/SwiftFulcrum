// WebSocketConnection~TaskLifecycle.swift

import Foundation

extension WebSocketConnection {
    func updateURL(_ newURL: URL) { self.url = newURL }

    func createNewTask(with url: URL? = nil, receiverCancellation: ReceiverCancellation = .cancel) async {
        if let url { self.url = url }

        let suppressesReaderStart: Bool
        switch receiverCancellation {
        case .cancel:
            suppressesReaderStart = true
            readerStartSuppressionCount += 1
            await cancelReceiverTask()
        case .preserve:
            suppressesReaderStart = false
            break
        }
        defer {
            if suppressesReaderStart {
                readerStartSuppressionCount -= 1
            }
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
        guard let receiverMessageStreamGenerationIdentifier,
              let receivedTask else {
            return
        }
        receivedTask.cancel()
        await receivedTask.value
        guard self.receiverMessageStreamGenerationIdentifier
                == receiverMessageStreamGenerationIdentifier else {
            return
        }
        self.receivedTask = nil
        self.receiverMessageStreamGenerationIdentifier = nil
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
