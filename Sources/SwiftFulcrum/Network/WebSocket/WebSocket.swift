// WebSocket.swift

import Foundation

actor WebSocket {
    var url: URL
    var task: URLSessionWebSocketTask?
    private var connectionStateTracker: ConnectionStateTracker
    let network: Fulcrum.Configuration.Network
    
    private var sharedMessagesStream: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>?
    var messageContinuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Continuation?
    
    let reconnector: Reconnector
    var logger: Log.Handler
    
    private var reconnectAttemptCount = 0
    private var reconnectSuccessCount = 0
    
    private var isConnectionInFlight = false
    private var connectWaiters = [CheckedContinuation<Bool, Error>]()
    var isConnected: Bool { get async { await connectionStateTracker.state == .connected } }
    
    private var nextOutgoingMessageIdentifier: UInt64 = 0
    private var nextIncomingMessageIdentifier: UInt64 = 0
    
    private var receivedTask: Task<Void, Never>?
    private var shouldAutomaticallyReceive = false
    
    var sharedLifecycleStream: AsyncStream<Lifecycle.Event>?
    var lifecycleContinuation: AsyncStream<Lifecycle.Event>.Continuation?
    
    let session: URLSession
    private let connectionTimeout: TimeInterval
    private let maximumMessageSize: Int
    
    private let tlsDescriptor: TLSDescriptor?
    var metrics: MetricsCollectable?
    
    init(url: URL,
         configuration: Configuration = .init(),
         reconnectConfiguration: Reconnector.Configuration = .basic,
         connectionTimeout: TimeInterval = 10,
         sleep: @escaping @Sendable (Duration) async throws -> Void = { duration in try await Task.sleep(for: duration) },
         jitter: @escaping @Sendable (ClosedRange<Double>) -> Double = { range in .random(in: range) }) {
        self.url = url
        self.task = nil
        self.connectionStateTracker = .init()
        self.reconnector = Reconnector(
            reconnectConfiguration,
            network: configuration.network,
            sleep: sleep,
            jitter: jitter
        )
        self.connectionTimeout = connectionTimeout
        self.network = configuration.network
        
        self.metrics = configuration.metrics
        self.logger = configuration.logger ?? Log.ConsoleHandler()
        self.tlsDescriptor = configuration.tlsDescriptor
        self.maximumMessageSize = configuration.maximumMessageSize
        
        if let session = configuration.session {
            self.session = session
        } else {
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.timeoutIntervalForRequest = connectionTimeout
            sessionConfiguration.timeoutIntervalForResource = connectionTimeout
            
            if let descriptor = configuration.tlsDescriptor {
                self.session = URLSession(configuration: sessionConfiguration, delegate: descriptor.delegate, delegateQueue: nil)
            } else {
                self.session = URLSession(configuration: sessionConfiguration)
            }
        }
    }
}

// MARK: - Create & Cancel
extension WebSocket {
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
    
    func makeDiagnosticsSnapshot() -> Fulcrum.Diagnostics.TransportSnapshot {
        .init(
            reconnectAttempts: reconnectAttemptCount,
            reconnectSuccesses: reconnectSuccessCount
        )
    }
}

// MARK: - Connect & Disconnect & Reconnect
extension WebSocket {
    func connect(
        shouldEmitLifecycle: Bool = true,
        shouldAllowFailover: Bool = true,
        shouldCancelReceiver: Bool = true
    ) async throws {
        guard await !self.isConnected else { return }
        await updateConnectionState(.connecting)
        
        await createNewTask(with: nil, shouldCancelReceiver: shouldCancelReceiver)
        guard let task else {
            throw Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
        }
        
        task.resume()
        emitLog(.info, "connect.begin")
        
        do {
            let isConnected = try await waitForConnection(timeout: connectionTimeout)
            if isConnected {
                await updateConnectionState(.connected)
                emitLog(.info, "connect.succeeded")
                await metrics?.didConnect(url: url, network: network)
                if shouldEmitLifecycle { emitLifecycle(.connected(isReconnect: false)) }
                ensureAutomaticReceiving()
            } else {
                await updateConnectionState(.disconnected)
                task.cancel(with: .goingAway, reason: "Connection timed out.".data(using: .utf8))
                emitLog(.error, "connect.timeout")
                try await performInitialFailoverIfNeeded(
                    shouldAllowFailover: shouldAllowFailover,
                    failure: Fulcrum.Error.transport(
                        .connectionClosed(closeInformation.code, closeInformation.reason)
                    )
                )
            }
        } catch let networkError as Fulcrum.Error.Network {
            await updateConnectionState(.disconnected)
            task.cancel(with: .goingAway, reason: "Network error during connect.".data(using: .utf8))
            try await performInitialFailoverIfNeeded(
                shouldAllowFailover: shouldAllowFailover,
                failure: Fulcrum.Error.transport(.network(networkError))
            )
        } catch {
            await updateConnectionState(.disconnected)
            task.cancel(with: .goingAway, reason: "Connect failed.".data(using: .utf8))
            try await performInitialFailoverIfNeeded(
                shouldAllowFailover: shouldAllowFailover,
                failure: error
            )
        }
    }
    
    private func performInitialFailoverIfNeeded(
        shouldAllowFailover: Bool,
        failure: Error
    ) async throws {
        guard shouldAllowFailover else { throw failure }
        
        emitLog(
            .warning,
            "connect.failover",
            metadata: ["error": failure.localizedDescription]
        )
        
        do {
            await updateConnectionState(.reconnecting)
            try await reconnector.attemptReconnection(
                for: self,
                shouldCancelReceiver: true,
                isInitialConnection: true
            )
        } catch {
            emitLog(
                .error,
                "connect.failover_exhausted",
                metadata: ["error": error.localizedDescription]
            )
            
            throw error
        }
    }
    
    func reconnect(with url: URL? = nil) async throws {
        await disconnect(with: "WebSocket.reconnect()")
        await updateConnectionState(.reconnecting)
        try await reconnector.attemptReconnection(for: self, with: url, shouldCancelReceiver: false)
    }
    
    func disconnect(with reason: String? = nil) async {
        await cancelReceiverTask()
        
        let information = closeInformation
        
        task?.cancel(with: .goingAway, reason: reason?.data(using: .utf8))
        task = nil
        await updateConnectionState(.disconnected)
        
        finishConnectWaiters(.failure(Fulcrum.Error.transport(.connectionClosed(information.code, information.reason))))
        
        messageContinuation?.finish(
            throwing: Fulcrum.Error.transport(.connectionClosed(information.code, information.reason))
        )
        
        await metrics?.didDisconnect(url: url, closeCode: information.code, reason: reason)
        await resetMessageStreamAndReader()
        emitLog(.info, "disconnect", metadata: ["reason": reason ?? "nil",
                                                "code": String(information.code.rawValue)])
        emitLifecycle(.disconnected(code: information.code, reason: reason))
    }
}

extension WebSocket {
    private func finishConnectWaiters(_ result: Result<Bool, Error>) {
        let waiters = connectWaiters
        connectWaiters.removeAll(keepingCapacity: false)
        isConnectionInFlight = false
        for continuation in waiters {
            switch result {
            case .success(let isSuccessful): continuation.resume(returning: isSuccessful)
            case .failure(let error): continuation.resume(throwing: error)
            }
        }
    }
    
    private func waitForConnection(timeout: TimeInterval) async throws -> Bool {
        if await isConnected { return true }
        
        if isConnectionInFlight {
            return try await withCheckedThrowingContinuation { continuation in
                connectWaiters.append(continuation)
            }
        }
        
        isConnectionInFlight = true
        do {
            let isSuccessful = try await waitForConnectionOnce(timeout: timeout)
            finishConnectWaiters(.success(isSuccessful))
            return isSuccessful
        } catch {
            finishConnectWaiters(.failure(error))
            throw error
        }
    }
    
    private func waitForConnectionOnce(timeout: TimeInterval) async throws -> Bool {
        guard let task else {
            throw Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
        }
        
        let (stream, continuation) = AsyncThrowingStream<Bool, Error>.makeStream()
        let currentURL = self.url
        let metrics = self.metrics
        
        task.sendPing { error in
            if let metrics { Task { await metrics.didPing(url: currentURL, error: error) } }
            if let error {
                continuation.finish(throwing: Fulcrum.Error.Network.tlsNegotiationFailed(error))
            } else {
                _ = continuation.yield(true); continuation.finish()
            }
        }
        
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                var iterator = stream.makeAsyncIterator()
                guard let isSuccessful = try await iterator.next() else {
                    return false
                }
                return isSuccessful
            }
            
            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                return false
            }
            
            let winner = try await group.next() ?? false
            group.cancelAll()
            return winner
        }
    }
}

// MARK: - Send
extension WebSocket {
    func send(data: Data) async throws {
        guard let task else { throw Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason)) }
        
        let message = URLSessionWebSocketTask.Message.data(data)
        let messageIdentifier = makeOutgoingMessageIdentifier()
        emitLog(.info,
                "send.begin",
                metadata: [
                    "messageIdentifier": String(messageIdentifier),
                    "payloadType": "data",
                    "byteCount": String(data.count)
                ])
        try await task.send(message)
        await metrics?.didSend(url: url, message: message)
        emitLog(.info,
                "send.succeeded",
                metadata: [
                    "messageIdentifier": String(messageIdentifier),
                    "payloadType": "data",
                    "byteCount": String(data.count)
                ])
    }
    
    func send(string: String) async throws {
        guard let task else { throw Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason)) }
        
        let message = URLSessionWebSocketTask.Message.string(string)
        let messageIdentifier = makeOutgoingMessageIdentifier()
        emitLog(.info,
                "send.begin",
                metadata: [
                    "messageIdentifier": String(messageIdentifier),
                    "payloadType": "string",
                    "characterCount": String(string.count)
                ])
        try await task.send(message)
        await metrics?.didSend(url: url, message: message)
        emitLog(.info,
                "send.succeeded",
                metadata: [
                    "messageIdentifier": String(messageIdentifier),
                    "payloadType": "string",
                    "characterCount": String(string.count)
                ])
    }
}

// MARK: - Receive
extension WebSocket {
    private func startReader() {
        guard receivedTask == nil else { return }
        receivedTask = Task { [weak self] in
            guard let self else { return }
            await self.receiveContinuously()
        }
    }
    
    func ensureAutomaticReceiving() {
        guard shouldAutomaticallyReceive else { return }
        if sharedMessagesStream == nil {
            _ = makeMessageStream(shouldEnableAutomaticResumption: true)
            return
        }
        
        if receivedTask == nil { startReader() }
    }
    
    func makeMessageStream(shouldEnableAutomaticResumption: Bool = true) -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> {
        shouldAutomaticallyReceive = shouldEnableAutomaticResumption
        
        if let stream = sharedMessagesStream {
            emitLog(.info,
                    "message_stream.reuse",
                    metadata: ["automaticResumption": String(shouldEnableAutomaticResumption)])
            if shouldEnableAutomaticResumption && receivedTask == nil { startReader() }
            return stream
        }
        
        emitLog(.info,
                "message_stream.create",
                metadata: ["automaticResumption": String(shouldEnableAutomaticResumption)])
        let stream = AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> { continuation in
            self.messageContinuation = continuation
            self.startReader()
            continuation.onTermination = { @Sendable _ in
                Task { await self.resetMessageStreamAndReader() }
            }
        }
        
        sharedMessagesStream = stream
        
        return stream
    }
    
    private func resetMessageStreamAndReader() async {
        await cancelReceiverTask()
        emitLog(.info, "message_stream.reset")
        sharedMessagesStream = nil
        messageContinuation = nil
    }
    
    private func makeOutgoingMessageIdentifier() -> UInt64 {
        nextOutgoingMessageIdentifier &+= 1
        return nextOutgoingMessageIdentifier
    }
    
    private func makeIncomingMessageIdentifier() -> UInt64 {
        nextIncomingMessageIdentifier &+= 1
        return nextIncomingMessageIdentifier
    }
    
    private func payloadMetadata(for message: URLSessionWebSocketTask.Message) -> (type: String, length: Int) {
        switch message {
        case .data(let data):
            return ("data", data.count)
        case .string(let string):
            return ("string", string.count)
        @unknown default:
            return ("unknown", 0)
        }
    }
    
    private func receiveContinuously() async {
        defer { receivedTask = nil }
        
        while !Task.isCancelled {
            guard let task = task else { break }
            
            do {
                let message = try await withTaskCancellationHandler {
                    try await task.receive()
                } onCancel: {
                    task.cancel(with: .goingAway, reason: nil)
                }
                let metadata = payloadMetadata(for: message)
                emitLog(.info,
                        "receive.message",
                        metadata: [
                            "messageIdentifier": String(makeIncomingMessageIdentifier()),
                            "payloadType": metadata.type,
                            "length": String(metadata.length)
                        ])
                switch messageContinuation?.yield(with: .success(message)) {
                case .some(.enqueued): break
                default:
                    messageContinuation?.finish()
                    messageContinuation = nil
                    break
                }
                await metrics?.didReceive(url: url, message: message)
            } catch let urlError as URLError where urlError.code == .cancelled {
                break
            } catch {
                if Task.isCancelled { break }
                emitLog(.warning, "receive.failed_reconnecting",
                        metadata: ["error": (error as NSError).localizedDescription])
                do {
                    await updateConnectionState(.reconnecting)
                    try await reconnector.attemptReconnection(for: self, shouldCancelReceiver: false)
                    emitLog(.info, "receive.reconnected")
                    await updateConnectionState(.connected)
                    continue
                } catch {
                    messageContinuation?.finish(throwing: error)
                    messageContinuation = nil
                    break
                }
            }
            
            await Task.yield()
        }
    }
}

extension WebSocket {
    func emitLog(
        _ level: Log.Level,
        _ message: @autoclosure () -> String,
        metadata: [String: String] = .init(),
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) {
        var mergedMetadata = [
            "component": "WebSocket",
            "url": url.absoluteString,
            "network": network.resourceName
        ]
        mergedMetadata.merge(metadata, uniquingKeysWith: { _, new in new })
        logger.log(level, message(), metadata: mergedMetadata, file: file, function: function, line: line)
    }
}
