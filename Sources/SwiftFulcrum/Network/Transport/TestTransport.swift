// TestTransport.swift

import Foundation

actor TestTransport: Transportable {
    private var currentState: Fulcrum.ConnectionState = .idle
    private var currentCloseInformation: CloseInformation = (.invalid, nil)
    private var currentURL: URL = URL(string: "wss://example.invalid")!
    
    private var sharedMessageStream: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>?
    private var messageContinuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Continuation?
    
    private var sharedLifecycleStream: AsyncStream<FulcrumTransportLifecycle.Event>?
    private var lifecycleContinuation: AsyncStream<FulcrumTransportLifecycle.Event>.Continuation?
    
    private var sharedConnectionStateStream: AsyncStream<Fulcrum.ConnectionState>?
    private var connectionStateContinuation: AsyncStream<Fulcrum.ConnectionState>.Continuation?
    
    private var sharedOutgoingMessages: AsyncStream<URLSessionWebSocketTask.Message>?
    private var outgoingContinuation: AsyncStream<URLSessionWebSocketTask.Message>.Continuation?
    
    var connectionState: Fulcrum.ConnectionState { currentState }
    var closeInformation: CloseInformation { currentCloseInformation }
    var endpoint: URL { currentURL }
    
    var outgoingMessages: AsyncStream<URLSessionWebSocketTask.Message> {
        if let sharedOutgoingMessages { return sharedOutgoingMessages }
        let stream = AsyncStream<URLSessionWebSocketTask.Message> { continuation in
            outgoingContinuation = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.resetOutgoingStream() }
            }
        }
        sharedOutgoingMessages = stream
        return stream
    }
    
    func connect() async throws {
        updateState(to: .connected)
        lifecycleContinuation?.yield(.connected(isReconnect: false))
    }
    
    func disconnect(with reason: String?) async {
        currentCloseInformation = (.normalClosure, reason)
        updateState(to: .disconnected)
        lifecycleContinuation?.yield(.disconnected(code: .normalClosure, reason: reason))
        messageContinuation?.finish(throwing: Fulcrum.Error.transport(.connectionClosed(.normalClosure, reason)))
    }
    
    func reconnect(with url: URL?) async throws {
        _ = url
        updateState(to: .reconnecting)
        try? await Task.sleep(for: .milliseconds(10))
        lifecycleContinuation?.yield(.connected(isReconnect: true))
        try? await Task.sleep(for: .milliseconds(10))
        updateState(to: .connected)
    }
    
    func send(data: Data) async throws {
        outgoingContinuation?.yield(.data(data))
    }
    
    func send(string: String) async throws {
        outgoingContinuation?.yield(.string(string))
    }
    
    func makeMessageStream() async -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> {
        if let sharedMessageStream { return sharedMessageStream }
        let stream = AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> { continuation in
            messageContinuation = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.resetMessageStream() }
            }
        }
        sharedMessageStream = stream
        return stream
    }
    
    func makeLifecycleEvents() async -> AsyncStream<FulcrumTransportLifecycle.Event> {
        if let sharedLifecycleStream { return sharedLifecycleStream }
        let stream = AsyncStream<FulcrumTransportLifecycle.Event> { continuation in
            lifecycleContinuation = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.resetLifecycleStream() }
            }
        }
        sharedLifecycleStream = stream
        return stream
    }
    
    func makeConnectionStateEvents() async -> AsyncStream<Fulcrum.ConnectionState> {
        if let sharedConnectionStateStream { return sharedConnectionStateStream }
        let stream = AsyncStream<Fulcrum.ConnectionState> { continuation in
            connectionStateContinuation = continuation
            continuation.yield(currentState)
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.resetConnectionStateStream() }
            }
        }
        sharedConnectionStateStream = stream
        return stream
    }
    
    func makeDiagnosticsSnapshot() async -> Fulcrum.Diagnostics.TransportSnapshot {
        .init(reconnectAttempts: 0, reconnectSuccesses: 0)
    }
    
    func updateMetrics(_ collector: MetricsCollectable?) async { _ = collector }
    
    func updateLogger(_ handler: Log.Handler?) async { _ = handler }
    
    func inject(message: URLSessionWebSocketTask.Message) {
        _ = messageContinuation?.yield(with: .success(message))
    }
    
    func injectLifecycleEvent(_ event: FulcrumTransportLifecycle.Event) {
        switch event {
        case .connected(let isReconnect):
            updateState(to: isReconnect ? .reconnecting : .connected)
            updateState(to: .connected)
        case .disconnected(let code, let reason):
            currentCloseInformation = (code, reason)
            updateState(to: .disconnected)
        }
        lifecycleContinuation?.yield(event)
    }
    
    private func updateState(to newState: Fulcrum.ConnectionState) {
        guard currentState != newState else { return }
        currentState = newState
        connectionStateContinuation?.yield(newState)
    }
    
    private func resetMessageStream() async {
        sharedMessageStream = nil
        messageContinuation = nil
    }
    
    private func resetLifecycleStream() async {
        sharedLifecycleStream = nil
        lifecycleContinuation = nil
    }
    
    private func resetConnectionStateStream() async {
        sharedConnectionStateStream = nil
        connectionStateContinuation = nil
    }
    
    private func resetOutgoingStream() async {
        sharedOutgoingMessages = nil
        outgoingContinuation = nil
    }
}
