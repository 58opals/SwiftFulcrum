import Foundation
import Network

actor WebSocket {
    var url: URL
    private var task: URLSessionWebSocketTask?
    private var state: ConnectionState
    
    private var sharedMessagesStream: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>?
    private var messageContinuation: AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Continuation?
    
    let reconnector: Reconnector
    
    var isConnected: Bool { state == .connected }
    
    private var receivedTask: Task<Void, Never>?
    
    init(url: URL, reconnectConfiguration: Reconnector.Configuration = .defaultConfiguration) {
        self.url = url
        self.task = nil
        self.state = .disconnected
        self.reconnector = Reconnector(reconnectConfiguration)
    }
}

// MARK: - Create & Cancel
extension WebSocket {
    func createNewTask(with url: URL? = nil) {
        if let url { self.url = url }
        
        Task { await cancelReceiverTask() }
        task?.cancel(with: .goingAway, reason: "Recreating task.".data(using: .utf8))
        task = URLSession.shared.webSocketTask(with: self.url)
    }
    
    func cancelReceiverTask() async {
        receivedTask?.cancel()
        await receivedTask?.value
        receivedTask = nil
    }
    
    func getCurrentCloseInformation() -> (code: URLSessionWebSocketTask.CloseCode, reason: String?) {
        let code   = task?.closeCode ?? .invalid
        let reason = task?.closeReason.flatMap { String(data: $0, encoding: .utf8) }
        return (code, reason)
    }
}

// MARK: - Connect & Disconnect & Reconnect
extension WebSocket {
    private func waitForConnection(timeout: TimeInterval) async throws -> Bool {
        guard let task else {
            throw Error.connection(url: url, reason: .failed)
        }
        
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    task.sendPing { error in
                        if let error { continuation.resume(throwing: error) }
                        else         { continuation.resume(returning: true) }
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
            createNewTask()
        }
        
        guard let task else {
            throw Error.connection(url: url, reason: .failed)
        }
        
        task.resume()
        print("WebSocket (\(self.url.description)) is connecting...")
        
        let isConnected = try await waitForConnection(timeout: 2)
        switch isConnected {
        case true:
            state = .connected
            print("WebSocket (\(self.url.description)) is connected.")
        case false:
            state = .disconnected
            print("WebSocket (\(self.url.description)) failed to connect.")
            throw Error.connection(url: url, reason: .failed)
        }
    }
    
    func disconnect(with reason: String? = nil) async {
        await cancelReceiverTask()
        
        task?.cancel(with: .goingAway, reason: reason?.data(using: .utf8))
        let closeInformation = getCurrentCloseInformation()
        task = nil
        state = .disconnected
        
        messageContinuation?.finish(throwing: Error.closed(code: closeInformation.code, reason: closeInformation.reason))
        
        resetMessageStream()
        print("WebSocket (\(self.url.description)) is disconnected.")
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
        guard let task else { throw WebSocket.Error.connection(url: url, reason: .failed) }
        
        let message = URLSessionWebSocketTask.Message.data(data)
        try await task.send(message)
    }
    
    func send(string: String) async throws {
        guard let task else { throw WebSocket.Error.connection(url: url, reason: .failed) }
        
        let message = URLSessionWebSocketTask.Message.string(string)
        try await task.send(message)
    }
}

// MARK: - Receive
extension WebSocket {
    func messages() -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> {
        if let stream = sharedMessagesStream {
            return stream
        }
        
        let stream = AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error> { continuation in
            self.messageContinuation = continuation
            
            self.receivedTask = Task { [weak self] in
                guard let self else { return }
                await self.receiveContinuously()
            }
            
            continuation.onTermination = { @Sendable _ in
                Task { await self.resetMessageStream() }
            }
        }
        
        sharedMessagesStream = stream
        return stream
    }
    
    private func resetMessageStream() {
        sharedMessagesStream = nil
        messageContinuation = nil
    }
    
    private func receiveContinuously() async {
        guard let task else {
            messageContinuation?.finish(throwing: WebSocket.Error.connection(url: url, reason: .failed))
            return
        }
        
        defer {
            state = .disconnected
            let closeInformation = getCurrentCloseInformation()
            messageContinuation?.finish(throwing: Error.closed(code: closeInformation.code, reason: closeInformation.reason))
            resetMessageStream()
        }
        
        do {
            try await withTaskCancellationHandler {
                while !Task.isCancelled {
                    let message = try await task.receive()
                    messageContinuation?.yield(with: .success(message))
                }
            } onCancel: {
                task.cancel(with: .goingAway, reason: nil)
            }
            messageContinuation?.finish()
        } catch is CancellationError {
            messageContinuation?.finish()
        } catch {
            messageContinuation?.finish(throwing: error)
        }
    }
}
