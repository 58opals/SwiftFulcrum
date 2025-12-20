// TransportStub.swift

import Foundation
@testable import SwiftFulcrum

actor TransportStub: Transportable {
    private var connectionStateValue: Fulcrum.ConnectionState = .idle
    private var closeInformationValue: CloseInformation = (.invalid, nil)
    private var currentEndpoint: URL
    
    private var incomingBuffer: [Result<URLSessionWebSocketTask.Message, Swift.Error>] = []
    private var incomingStream: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>?
    private var incomingContinuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Continuation?
    
    private var lifecycleBuffer: [FulcrumTransportLifecycle.Event] = []
    private var lifecycleStream: AsyncStream<FulcrumTransportLifecycle.Event>?
    private var lifecycleContinuation: AsyncStream<FulcrumTransportLifecycle.Event>.Continuation?
    
    private var connectionStateBuffer: [Fulcrum.ConnectionState] = []
    private var connectionStateStream: AsyncStream<Fulcrum.ConnectionState>?
    private var connectionStateContinuation: AsyncStream<Fulcrum.ConnectionState>.Continuation?
    
    private var outgoingQueue: [URLSessionWebSocketTask.Message] = []
    private var pendingOutgoingContinuations: [CheckedContinuation<URLSessionWebSocketTask.Message, Never>] = []
    private(set) var sentMessages: [URLSessionWebSocketTask.Message] = []
    
    init(endpoint: URL = URL(string: "wss://example.invalid")!) {
        self.currentEndpoint = endpoint
    }
    
    var connectionState: Fulcrum.ConnectionState { connectionStateValue }
    var closeInformation: CloseInformation { closeInformationValue }
    var endpoint: URL { currentEndpoint }
    
    func connect() async throws {
        updateConnectionState(to: .connected)
        enqueueLifecycleEvent(.connected(isReconnect: false))
    }
    
    func disconnect(with reason: String?) async {
        closeInformationValue = (.normalClosure, reason)
        updateConnectionState(to: .disconnected)
        enqueueLifecycleEvent(.disconnected(code: .normalClosure, reason: reason))
    }
    
    func reconnect(with url: URL?) async throws {
        if let url { currentEndpoint = url }
        updateConnectionState(to: .reconnecting)
    }
    
    func send(data: Data) async throws {
        recordOutgoing(.data(data))
    }
    
    func send(string: String) async throws {
        recordOutgoing(.string(string))
    }
    
    func makeMessageStream() async -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> {
        if let incomingStream { return incomingStream }
        var continuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Continuation!
        let stream = AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> { innerContinuation in
            continuation = innerContinuation
            innerContinuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.resetIncomingStream() }
            }
        }
        incomingStream = stream
        incomingContinuation = continuation
        flushIncomingBuffer()
        return stream
    }
    
    func makeLifecycleEvents() async -> AsyncStream<FulcrumTransportLifecycle.Event> {
        if let lifecycleStream { return lifecycleStream }
        var continuation: AsyncStream<FulcrumTransportLifecycle.Event>.Continuation!
        let stream = AsyncStream<FulcrumTransportLifecycle.Event> { innerContinuation in
            continuation = innerContinuation
            innerContinuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.resetLifecycleStream() }
            }
        }
        lifecycleStream = stream
        lifecycleContinuation = continuation
        flushLifecycleBuffer()
        return stream
    }
    
    func makeConnectionStateEvents() async -> AsyncStream<Fulcrum.ConnectionState> {
        if let connectionStateStream { return connectionStateStream }
        var continuation: AsyncStream<Fulcrum.ConnectionState>.Continuation!
        let stream = AsyncStream<Fulcrum.ConnectionState> { innerContinuation in
            continuation = innerContinuation
            innerContinuation.yield(connectionStateValue)
            innerContinuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.resetConnectionStateStream() }
            }
        }
        connectionStateStream = stream
        connectionStateContinuation = continuation
        flushConnectionStateBuffer()
        return stream
    }
    
    func makeDiagnosticsSnapshot() async -> Fulcrum.Diagnostics.TransportSnapshot {
        .init(reconnectAttempts: 0, reconnectSuccesses: 0)
    }
    func updateMetrics(_ collector: MetricsCollectable?) async { _ = collector }
    func updateLogger(_ handler: Log.Handler?) async { _ = handler }
    
    func enqueueIncoming(_ message: URLSessionWebSocketTask.Message) {
        incomingBuffer.append(.success(message))
        flushIncomingBuffer()
    }
    
    func enqueueLifecycleEvent(_ event: FulcrumTransportLifecycle.Event) {
        lifecycleBuffer.append(event)
        apply(event)
        flushLifecycleBuffer()
    }
    
    func nextOutgoing() async -> URLSessionWebSocketTask.Message {
        if !outgoingQueue.isEmpty {
            return outgoingQueue.removeFirst()
        }
        return await withCheckedContinuation { continuation in
            pendingOutgoingContinuations.append(continuation)
        }
    }
    
    private func recordOutgoing(_ message: URLSessionWebSocketTask.Message) {
        sentMessages.append(message)
        outgoingQueue.append(message)
        resolvePendingOutgoingContinuations()
    }
    
    private func resolvePendingOutgoingContinuations() {
        while !pendingOutgoingContinuations.isEmpty, !outgoingQueue.isEmpty {
            let continuation = pendingOutgoingContinuations.removeFirst()
            let message = outgoingQueue.removeFirst()
            continuation.resume(returning: message)
        }
    }
    
    private func updateConnectionState(to newState: Fulcrum.ConnectionState) {
        guard connectionStateValue != newState else { return }
        connectionStateValue = newState
        connectionStateBuffer.append(newState)
        flushConnectionStateBuffer()
    }
    
    private func apply(_ event: FulcrumTransportLifecycle.Event) {
        switch event {
        case .connected(let isReconnect):
            if isReconnect { updateConnectionState(to: .reconnecting) }
            updateConnectionState(to: .connected)
        case .disconnected(let code, let reason):
            closeInformationValue = (code, reason)
            updateConnectionState(to: .disconnected)
        }
    }
    
    private func flushIncomingBuffer() {
        guard let incomingContinuation else { return }
        for entry in incomingBuffer {
            switch entry {
            case .success(let message):
                incomingContinuation.yield(message)
            case .failure(let error):
                incomingContinuation.finish(throwing: error)
            }
        }
        incomingBuffer.removeAll()
    }
    private func flushLifecycleBuffer() {
        guard let lifecycleContinuation else { return }
        for event in lifecycleBuffer {
            lifecycleContinuation.yield(event)
        }
        lifecycleBuffer.removeAll()
    }
    private func flushConnectionStateBuffer() {
        guard let connectionStateContinuation else { return }
        for state in connectionStateBuffer {
            connectionStateContinuation.yield(state)
        }
        connectionStateBuffer.removeAll()
    }
    
    private func resetIncomingStream() async {
        incomingStream = nil
        incomingContinuation = nil
    }
    
    private func resetLifecycleStream() async {
        lifecycleStream = nil
        lifecycleContinuation = nil
    }
    
    private func resetConnectionStateStream() async {
        connectionStateStream = nil
        connectionStateContinuation = nil
    }
}

// MARK: - Helpers
func makeJSONObject(from message: URLSessionWebSocketTask.Message) throws -> [String: Any] {
    guard
        let data = message.dataPayload,
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { throw NSError(domain: "TransportStubTests", code: 0) }
    return json
}

func makeResponsePayload(id: String, result: Any) throws -> Data {
    try JSONSerialization.data(
        withJSONObject: [
            "jsonrpc": "2.0",
            "id": id,
            "result": result
        ]
    )
}

func makeErrorPayload(id: String, code: Int, message: String) throws -> Data {
    try JSONSerialization.data(
        withJSONObject: [
            "jsonrpc": "2.0",
            "id": id,
            "error": [
                "code": code,
                "message": message
            ]
        ]
    )
}

func makeEmptyPayload(id: String) throws -> Data {
    try JSONSerialization.data(
        withJSONObject: [
            "jsonrpc": "2.0",
            "id": id
        ]
    )
}

func makeSubscriptionNotification(method: String, parameters: [Any]) throws -> Data {
    try JSONSerialization.data(
        withJSONObject: [
            "jsonrpc": "2.0",
            "method": method,
            "params": parameters
        ]
    )
}
