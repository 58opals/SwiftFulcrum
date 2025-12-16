// Transportable_.swift

import Foundation

protocol Transportable: Sendable {
    typealias CloseInformation = (code: URLSessionWebSocketTask.CloseCode, reason: String?)
    
    var connectionState: Fulcrum.ConnectionState { get async }
    var closeInformation: CloseInformation { get async }
    var endpoint: URL { get async }
    
    func connect() async throws
    func disconnect(with reason: String?) async
    func reconnect(with url: URL?) async throws
    
    func send(data: Data) async throws
    func send(string: String) async throws
    
    func makeMessageStream() async -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>
    func makeLifecycleEvents() async -> AsyncStream<FulcrumTransportLifecycle.Event>
    func makeConnectionStateEvents() async -> AsyncStream<Fulcrum.ConnectionState>
    func makeDiagnosticsSnapshot() async -> Fulcrum.Diagnostics.TransportSnapshot
    
    func updateMetrics(_ collector: MetricsCollectable?) async
    func updateLogger(_ handler: Log.Handler?) async
}

public enum FulcrumTransportLifecycle {
    public enum Event: Sendable {
        case connected(isReconnect: Bool)
        case disconnected(code: URLSessionWebSocketTask.CloseCode, reason: String?)
    }
}
