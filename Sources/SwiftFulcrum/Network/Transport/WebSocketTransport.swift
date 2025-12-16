// WebSocketTransport.swift

import Foundation

actor WebSocketTransport: Transportable {
    let webSocket: WebSocket
    
    init(webSocket: WebSocket) {
        self.webSocket = webSocket
    }
    
    var connectionState: Fulcrum.ConnectionState { get async { mapConnectionState(await webSocket.connectionState) } }
    var closeInformation: CloseInformation { get async { await webSocket.closeInformation } }
    var endpoint: URL { get async { await webSocket.url } }
    
    func connect() async throws { try await webSocket.connect() }
    
    func disconnect(with reason: String?) async { await webSocket.disconnect(with: reason) }
    
    func reconnect(with url: URL?) async throws { try await webSocket.reconnect(with: url) }
    
    func send(data: Data) async throws { try await webSocket.send(data: data) }
    
    func send(string: String) async throws { try await webSocket.send(string: string) }
    
    func makeMessageStream() async -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> {
        await webSocket.makeMessageStream()
    }
    
    func makeLifecycleEvents() async -> AsyncStream<FulcrumTransportLifecycle.Event> {
        let baseStream = await webSocket.makeLifecycleEvents()
        return AsyncStream { continuation in
            let task = Task { [weak webSocket] in
                guard webSocket != nil else { return }
                for await event in baseStream {
                    switch event {
                    case .connected(let isReconnect):
                        continuation.yield(.connected(isReconnect: isReconnect))
                    case .disconnected(let code, let reason):
                        continuation.yield(.disconnected(code: code, reason: reason))
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }
    
    func makeConnectionStateEvents() async -> AsyncStream<Fulcrum.ConnectionState> {
        let baseStream = await webSocket.makeConnectionStateEvents()
        return AsyncStream { continuation in
            let task = Task { [weak webSocket] in
                guard webSocket != nil else { return }
                for await state in baseStream {
                    continuation.yield(mapConnectionState(state))
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }
    
    func makeDiagnosticsSnapshot() async -> Fulcrum.Diagnostics.TransportSnapshot { await webSocket.makeDiagnosticsSnapshot() }
    
    func updateMetrics(_ collector: MetricsCollectable?) async { await webSocket.updateMetrics(collector) }
    
    func updateLogger(_ handler: Log.Handler?) async { await webSocket.updateLogger(handler) }
    
    private func mapConnectionState(_ state: WebSocket.ConnectionState) -> Fulcrum.ConnectionState {
        switch state {
        case .idle: .idle
        case .connecting: .connecting
        case .connected: .connected
        case .disconnected: .disconnected
        case .reconnecting: .reconnecting
        }
    }
}
