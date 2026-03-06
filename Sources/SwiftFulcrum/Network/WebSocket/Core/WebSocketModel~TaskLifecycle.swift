import Foundation

extension WebSocketModel {
    func updateURL(_ newURL: URL) { self.url = newURL }
    
    func createNewTask(with url: URL? = nil, shouldCancelReceiver: Bool = true) async {
        if let url { self.url = url }
        
        if shouldCancelReceiver { await cancelReceiverTask() }
        task?.cancel(with: .goingAway, reason: "Recreating task.".data(using: .utf8))
        task = session.webSocketTask(with: self.url)
        task?.maximumMessageSize = maximumMessageSize
    }
    
    func cancelReceiverTask() async {
        receivedTask?.cancel()
        await receivedTask?.value
        receivedTask = nil
    }
    
    var closeInformation: (code: URLSessionWebSocketTask.CloseCode, reason: String?) {
        let code = task?.closeCode ?? .invalid
        let reason = task?.closeReason.flatMap { String(data: $0, encoding: .utf8) }
        return (code, reason)
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
    
    func makeDiagnosticsSnapshot() -> SwiftFulcrum.Client.Diagnostics.TransportSnapshot {
        .init(
            reconnectAttempts: reconnectAttemptCount,
            reconnectSuccesses: reconnectSuccessCount
        )
    }
}
