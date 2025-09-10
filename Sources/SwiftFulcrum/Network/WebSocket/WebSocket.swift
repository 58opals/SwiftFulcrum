// WebSocket.swift

import Foundation

public actor WebSocket {
    var url: URL
    var task: URLSessionWebSocketTask?
    private var state: ConnectionState
    
    private var sharedMessagesStream: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>?
    var messageContinuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Continuation?
    
    let reconnector: Reconnector
    var logger: Log.Handler
    
    private var connectInFlight = false
    private var connectWaiters = [CheckedContinuation<Bool, Error>]()
    var isConnected: Bool { state == .connected }
    
    private var receivedTask: Task<Void, Never>?
    private var wantsAutoReceive = false
    
    let session: URLSession
    private let connectionTimeout: TimeInterval
    
    private let tlsDescriptor: TLSDescriptor?
    var metrics: MetricsCollectable?
    
    public init(url: URL,
                configuration: Configuration = .init(),
                reconnectConfiguration: Reconnector.Configuration = .defaultConfiguration,
                connectionTimeout: TimeInterval = 10) {
        self.url = url
        self.task = nil
        self.state = .disconnected
        self.reconnector = Reconnector(reconnectConfiguration)
        self.connectionTimeout = connectionTimeout
        
        self.metrics = configuration.metrics
        self.logger = configuration.logger ?? Log.NoOpHandler()
        self.tlsDescriptor = configuration.tls
        
        if let session = configuration.session {
            self.session = session
        } else {
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.timeoutIntervalForRequest = connectionTimeout
            sessionConfiguration.timeoutIntervalForResource = connectionTimeout
            
            if let tls = configuration.tls {
                self.session = URLSession(configuration: sessionConfiguration, delegate: tls.delegate, delegateQueue: nil)
            } else {
                self.session = URLSession(configuration: sessionConfiguration)
            }
        }
    }
}

// MARK: - Create & Cancel

extension WebSocket {
    func setURL(_ newURL: URL) { self.url = newURL }
    
    func createNewTask(with url: URL? = nil, cancelReceiver: Bool = true) async {
        if let url { self.url = url }
        
        if cancelReceiver { await cancelReceiverTask() }
        task?.cancel(with: .goingAway, reason: "Recreating task.".data(using: .utf8))
        task = session.webSocketTask(with: self.url)
    }
    
    func cancelReceiverTask() async {
        receivedTask?.cancel()
        await receivedTask?.value
        receivedTask = nil
    }
    
    private func getCurrentCloseInformation() -> (code: URLSessionWebSocketTask.CloseCode, reason: String?) {
        let code = task?.closeCode ?? .invalid
        let reason = task?.closeReason.flatMap { String(data: $0, encoding: .utf8) }
        return (code, reason)
    }
    
    var closeInformation: (code: URLSessionWebSocketTask.CloseCode, reason: String?) { self.getCurrentCloseInformation() }
}

// MARK: - Connect & Disconnect & Reconnect

extension WebSocket {
    private func finishConnectWaiters(_ result: Result<Bool, Error>) {
        let waiters = connectWaiters
        connectWaiters.removeAll(keepingCapacity: false)
        connectInFlight = false
        for c in waiters {
            switch result {
            case .success(let ok): c.resume(returning: ok)
            case .failure(let e): c.resume(throwing: e)
            }
        }
    }
    
    private func waitForConnection(timeout: TimeInterval) async throws -> Bool {
        if isConnected { return true }
        
        if connectInFlight {
            return try await withCheckedThrowingContinuation { cont in
                connectWaiters.append(cont)
            }
        }
        
        connectInFlight = true
        do {
            let ok = try await waitForConnectionOnce(timeout: timeout)
            finishConnectWaiters(.success(ok))
            return ok
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
                var it = stream.makeAsyncIterator()
                guard let ok = try await it.next() else {
                    return false
                }
                return ok
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
    
    func connect() async throws {
        guard !self.isConnected else { return }
        state = .connecting

        await createNewTask(with: nil, cancelReceiver: true)

        guard let task else {
            throw Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
        }

        task.resume()
        emitLog(.info, "connect.begin")

        do {
            let ok = try await waitForConnection(timeout: connectionTimeout)
            if ok {
                state = .connected
                emitLog(.info, "connect.succeeded")
                await metrics?.didConnect(url: url)
                ensureAutoReceive()
            } else {
                state = .disconnected
                task.cancel(with: .goingAway, reason: "Connection timed out.".data(using: .utf8))
                emitLog(.error, "connect.timeout")
                throw Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
            }
        } catch let net as Fulcrum.Error.Network {
            throw Fulcrum.Error.transport(.network(net))
        }
    }
    
    func reconnect(with url: URL? = nil) async throws {
        let currentURL = self.url
        let newURL = url ?? currentURL
        if currentURL != newURL { await reconnector.resetReconnectionAttemptCount() }
        
        try await reconnector.attemptReconnection(for: self, with: url, cancelReceiver: false)
    }
    
    func disconnect(with reason: String? = nil) async {
        await cancelReceiverTask()
        
        let info = getCurrentCloseInformation()
        
        task?.cancel(with: .goingAway, reason: reason?.data(using: .utf8))
        task = nil
        state = .disconnected
        
        finishConnectWaiters(.failure(Fulcrum.Error.transport(.connectionClosed(info.code, info.reason))))
        
        messageContinuation?.finish(
            throwing: Fulcrum.Error.transport(.connectionClosed(info.code, info.reason))
        )
        
        await metrics?.didDisconnect(url: url, closeCode: info.code, reason: reason)
        await resetMessageStreamAndReader()
        emitLog(.info, "disconnect", metadata: ["reason": reason ?? "nil",
                                                "code": String(info.code.rawValue)])
    }
}

// MARK: - Send

extension WebSocket {
    func send(data: Data) async throws {
        guard let task else { throw Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason)) }
        
        let message = URLSessionWebSocketTask.Message.data(data)
        try await task.send(message)
        await metrics?.didSend(url: url, message: message)
    }
    
    func send(string: String) async throws {
        guard let task else { throw Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason)) }
        
        let message = URLSessionWebSocketTask.Message.string(string)
        try await task.send(message)
        await metrics?.didSend(url: url, message: message)
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
    
    func ensureAutoReceive() {
        guard wantsAutoReceive else { return }
        if sharedMessagesStream == nil {
            _ = messages(enableAutoResume: true)
            return
        }
        
        if receivedTask == nil { startReader() }
    }
    
    func messages(enableAutoResume: Bool = true) -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> {
        wantsAutoReceive = enableAutoResume
        
        if let stream = sharedMessagesStream {
            if enableAutoResume && receivedTask == nil { startReader() }
            return stream
        }
        
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
        sharedMessagesStream = nil
        messageContinuation = nil
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
                switch messageContinuation?.yield(with: .success(message)) {
                case .some(.enqueued): break
                default:
                    messageContinuation?.finish()
                    messageContinuation = nil
                    break
                }
                await metrics?.didReceive(url: url, message: message)
            } catch let e as URLError where e.code == .cancelled {
                break
            } catch {
                emitLog(.warning, "receive.failed_reconnecting",
                        metadata: ["error": (error as NSError).localizedDescription])
                do {
                    // preserve stream on auto-reconnect too
                    try await reconnector.attemptReconnection(for: self, cancelReceiver: false)
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
    func emitLog(_ level: Log.Level,
                 _ message: @autoclosure () -> String,
                 metadata: [String: String]? = nil,
                 file: String = #fileID, function: String = #function, line: UInt = #line) {
        var md = ["component": "WebSocket", "url": url.absoluteString]
        if let metadata { for (k, v) in metadata { md[k] = v } }
        logger.log(level, message(), metadata: md, file: file, function: function, line: line)
    }
}
