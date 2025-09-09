// WebSocket.swift

import Foundation
import Network

public actor WebSocket {
    var url: URL
    var task: URLSessionWebSocketTask?
    private var state: ConnectionState
    
    private var sharedMessagesStream: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>?
    var messageContinuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Continuation?
    
    let reconnector: Reconnector
    var logger: Log.Handler
    
    var isConnected: Bool { state == .connected }
    
    private var receivedTask: Task<Void, Never>?
    private var wantsAutoReceive = false
    
    var heartbeatTask: Task<Void, Never>?
    
    let session: URLSession
    private let connectionTimeout: TimeInterval
    let heartbeatConfiguration: Heartbeat.Configuration?
    
    private let tlsDescriptor: TLSDescriptor?
    var metrics: MetricsCollectable?
    
    public init(url: URL,
                configuration: Configuration = .init(),
                reconnectConfiguration: Reconnector.Configuration = .defaultConfiguration,
                connectionTimeout: TimeInterval = 10,
                heartbeatConfiguration: Heartbeat.Configuration? = nil) {
        self.url = url
        self.task = nil
        self.state = .disconnected
        self.reconnector = Reconnector(reconnectConfiguration)
        self.connectionTimeout = connectionTimeout
        self.heartbeatConfiguration = heartbeatConfiguration
        
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

// MARK: - Configuration
extension WebSocket {
    public struct TLSDescriptor: Sendable {
        public let options: NWProtocolTLS.Options
        public let delegate: URLSessionDelegate?
        
        public init(options: NWProtocolTLS.Options = .init(), delegate: URLSessionDelegate? = nil) {
            self.options = options
            self.delegate = delegate
        }
    }
    
    public struct Configuration: Sendable {
        public let session: URLSession?
        public let tls: TLSDescriptor?
        public let metrics: MetricsCollectable?
        public let logger: Log.Handler?
        
        public init(session: URLSession? = nil,
                    tls: TLSDescriptor? = nil,
                    metrics: MetricsCollectable? = nil,
                    logger: Log.Handler? = nil) {
            self.session = session
            self.tls = tls
            self.metrics = metrics
            self.logger = logger
        }
    }
    
    func updateMetrics(_ collector: MetricsCollectable?) {
        self.metrics = collector
    }
    
    func updateLogger(_ handler: Log.Handler?) {
        self.logger = handler ?? Log.NoOpHandler()
    }
}

// MARK: - Create & Cancel
extension WebSocket {
    func setURL(_ newURL: URL) { self.url = newURL }
    
    func createNewTask(with url: URL? = nil) async {
        if let url { self.url = url }
        
        await cancelReceiverTask()
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
    private func waitForConnection(timeout: TimeInterval) async throws -> Bool {
        guard let task else { throw Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason)) }
        
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            let currentURL = self.url
            let metrics = self.metrics
            
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    task.sendPing { error in
                        if let metrics { Task { await metrics.didPing(url: currentURL, error: error) } }
                        if let error {
                            continuation.resume(throwing: Fulcrum.Error.Network.tlsNegotiationFailed(error))
                        } else {
                            continuation.resume(returning: true)
                        }
                    }
                }
            }
            
            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                return false
            }
            
            let result = try await group.next() ?? false
            group.cancelAll()
            
            return result
        }
    }
    
    func connect() async throws {
        if !self.isConnected {
            state = .connecting
            await createNewTask()
        }
        
        guard let task else { throw Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason)) }
        
        task.resume()
        emitLog(.info, "connect.begin")
        
        do {
            let isConnected = try await waitForConnection(timeout: connectionTimeout)
            switch isConnected {
            case true:
                state = .connected
                emitLog(.info, "connect.succeeded")
                await metrics?.didConnect(url: url)
                ensureAutoReceive()
                startHeartbeatIfNeeded()
            case false:
                state = .disconnected
                task.cancel(with: .goingAway, reason: "Connection timed out.".data(using: .utf8))
                emitLog(.error, "connect.timeout")
                throw Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
            }
        } catch let networkError as Fulcrum.Error.Network {
            throw Fulcrum.Error.transport(.network(networkError))
        }
    }
    
    func disconnect(with reason: String? = nil) async {
        await cancelReceiverTask()
        await stopHeartbeat()
        
        task?.cancel(with: .goingAway, reason: reason?.data(using: .utf8))
        task = nil
        state = .disconnected
        
        messageContinuation?.finish(throwing: Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason)))
        
        await metrics?.didDisconnect(url: url, closeCode: closeInformation.code, reason: reason)
        
        await resetMessageStreamAndReader()
        emitLog(.info, "disconnect", metadata: ["reason": reason ?? "nil",
                                                "code": String(closeInformation.code.rawValue)])
        
    }
    
    
    func reconnect(with url: URL? = nil) async throws {
        let currentURL = self.url
        let newURL = url ?? currentURL
        
        if currentURL != newURL {
            await reconnector.resetReconnectionAttemptCount()
        }
        
        try await reconnector.attemptReconnection(for: self, with: url)
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
    func ensureAutoReceive() {
        guard wantsAutoReceive, sharedMessagesStream == nil else { return }
        _ = messages()
    }
    
    func messages(enableAutoResume: Bool = true) -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> {
        wantsAutoReceive = enableAutoResume
        
        if let stream = sharedMessagesStream { return stream }
        
        let stream = AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> { continuation in
            self.messageContinuation = continuation
            
            self.receivedTask = Task { [weak self] in
                guard let self else { return }
                await self.receiveContinuously()
            }
            
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
        while !Task.isCancelled {
            guard let task = task else { break }
            
            do {
                let message = try await withTaskCancellationHandler {
                    try await task.receive()
                } onCancel: {
                    task.cancel(with: .goingAway, reason: nil)
                }
                
                switch messageContinuation?.yield(with: .success(message)) {
                case .some(.enqueued):
                    break
                default:
                    messageContinuation?.finish()
                    messageContinuation = nil
                    break
                }
                await metrics?.didReceive(url: url, message: message)
            } catch let error as URLError {
                if error.code == .cancelled {
                    break
                }
            } catch {
                emitLog(.warning,
                        "receive.failed_reconnecting",
                        metadata: ["error": (error as NSError).localizedDescription])
                
                do {
                    try await reconnector.attemptReconnection(for: self)
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
