// TransportTestActor.swift

import Foundation
@testable import SwiftFulcrum

actor TransportTestActor: TransportAdapter {
    private var connectionStateValue: SwiftFulcrum.Client.ConnectionState = .idle
    private var closeInformationValue: CloseInformation = (.invalid, nil)
    private var currentEndpoint: URL

    private var incomingBuffer: [Result<URLSessionWebSocketTask.Message, Swift.Error>] = .init()
    private var incomingStream: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>?
    private var incomingContinuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Continuation?

    private var lifecycleBuffer: [SwiftFulcrum.Transport.State.Event] = .init()
    private var lifecycleStream: AsyncStream<SwiftFulcrum.Transport.State.Event>?
    private var lifecycleContinuation: AsyncStream<SwiftFulcrum.Transport.State.Event>.Continuation?

    private var connectionStateBuffer: [SwiftFulcrum.Client.ConnectionState] = .init()
    private var connectionStateStream: AsyncStream<SwiftFulcrum.Client.ConnectionState>?
    private var connectionStateContinuation: AsyncStream<SwiftFulcrum.Client.ConnectionState>.Continuation?

    private var outgoingQueue: [URLSessionWebSocketTask.Message] = .init()
    private var pendingOutgoingContinuations: [CheckedContinuation<URLSessionWebSocketTask.Message, Never>] = .init()
    private(set) var sentMessages: [URLSessionWebSocketTask.Message] = .init()
    var connectDelay: Duration?
    var outgoingSendDelay: Duration?
    var outgoingSendFailuresByMethodPath: [String: Swift.Error] = .init()

    var reconnectFailure: Swift.Error?
    var reconnectAttempts = 0

    init(endpoint: URL = URL(string: "wss://example.invalid")!) {
        self.currentEndpoint = endpoint
    }

    var connectionState: SwiftFulcrum.Client.ConnectionState { connectionStateValue }
    var closeInformation: CloseInformation { closeInformationValue }
    var endpoint: URL { currentEndpoint }

    func connect() async throws {
        try await applyConnectDelayIfNeeded()
        updateConnectionState(to: .connected)
        enqueueLifecycleEvent(.connected(isReconnect: false))
    }

    func disconnect(with reason: String?) async {
        closeInformationValue = (.normalClosure, reason)
        updateConnectionState(to: .disconnected)
        enqueueLifecycleEvent(.disconnected(code: .normalClosure, reason: reason))
    }

    func reconnect(with url: URL?) async throws {
        reconnectAttempts += 1
        if let reconnectFailure {
            throw reconnectFailure
        }
        if let url { currentEndpoint = url }
        updateConnectionState(to: .reconnecting)
    }

    func send(data: Data) async throws {
        try await applyOutgoingSendDelayIfNeeded()
        if let error = consumeOutgoingSendFailure(from: data) {
            throw error
        }
        recordOutgoing(.data(data))
    }

    func send(string: String) async throws {
        try await applyOutgoingSendDelayIfNeeded()
        if let data = string.data(using: .utf8), let error = consumeOutgoingSendFailure(from: data) {
            throw error
        }
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

    func makeLifecycleEvents() async -> AsyncStream<SwiftFulcrum.Transport.State.Event> {
        if let lifecycleStream { return lifecycleStream }
        var continuation: AsyncStream<SwiftFulcrum.Transport.State.Event>.Continuation!
        let stream = AsyncStream<SwiftFulcrum.Transport.State.Event> { innerContinuation in
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

    func makeConnectionStateEvents() async -> AsyncStream<SwiftFulcrum.Client.ConnectionState> {
        if let connectionStateStream { return connectionStateStream }
        var continuation: AsyncStream<SwiftFulcrum.Client.ConnectionState>.Continuation!
        let stream = AsyncStream<SwiftFulcrum.Client.ConnectionState> { innerContinuation in
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

    func makeDiagnosticsSnapshot() async -> ClientDiagnosticsTransportState {
        .init(reconnectAttempts: 0, reconnectSuccesses: 0)
    }

    func updateMetrics(_ collector: SwiftFulcrum.Metrics.MetricsClient?) async { _ = collector }

    func updateLogger(_ handler: SwiftFulcrum.Logging.Adapter?) async { _ = handler }

    func registerQuietResponse(for identifier: UUID) async { _ = identifier }

    func enqueueIncoming(_ message: URLSessionWebSocketTask.Message) {
        incomingBuffer.append(.success(message))
        flushIncomingBuffer()
    }

    func enqueueLifecycleEvent(_ event: SwiftFulcrum.Transport.State.Event) {
        lifecycleBuffer.append(event)
        apply(event)
        flushLifecycleBuffer()
    }

    func dequeueOutgoing() async -> URLSessionWebSocketTask.Message {
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

    private func consumeOutgoingSendFailure(from data: Data) -> Swift.Error? {
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let methodPath = jsonObject["method"] as? String
        else {
            return nil
        }

        return outgoingSendFailuresByMethodPath.removeValue(forKey: methodPath)
    }
    
    private func applyOutgoingSendDelayIfNeeded() async throws {
        guard let outgoingSendDelay else { return }
        try await Task.sleep(for: outgoingSendDelay)
    }
    
    private func applyConnectDelayIfNeeded() async throws {
        guard let connectDelay else { return }
        try await Task.sleep(for: connectDelay)
    }

    private func resolvePendingOutgoingContinuations() {
        while !pendingOutgoingContinuations.isEmpty, !outgoingQueue.isEmpty {
            let continuation = pendingOutgoingContinuations.removeFirst()
            let message = outgoingQueue.removeFirst()
            continuation.resume(returning: message)
        }
    }

    private func updateConnectionState(to newState: SwiftFulcrum.Client.ConnectionState) {
        guard connectionStateValue != newState else { return }
        connectionStateValue = newState
        connectionStateBuffer.append(newState)
        flushConnectionStateBuffer()
    }

    private func apply(_ event: SwiftFulcrum.Transport.State.Event) {
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
