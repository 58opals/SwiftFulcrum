import Foundation
import Network

actor WebSocket {
    var url: URL
    private var task: URLSessionWebSocketTask?
    private var state: ConnectionState
    
    private var receiveTask: Task<Void, Never>?
    let reconnector: Reconnector
    
    var isConnected: Bool { state == .connected }
    
    init(url: URL, reconnectConfiguration: Reconnector.Configuration = .defaultConfiguration) {
        self.url = url
        self.task = nil
        self.state = .disconnected
        self.reconnector = Reconnector(reconnectConfiguration)
    }
}

// MARK: - Create
extension WebSocket {
    func createNewTask(with url: URL? = nil) {
        if let url { self.url = url }
        
        task?.cancel(with: .goingAway, reason: "Recreating task.".data(using: .utf8))
        self.task = nil
        
        self.task = URLSession.shared.webSocketTask(with: self.url)
    }
}

// MARK: - Connect & Disconnect & Reconnect
extension WebSocket {
    private func waitForConnection(timeout: TimeInterval) async throws -> Bool {
        let ping = URLSessionWebSocketTask.Message.string("ping")
        
        do {
            try await task?.send(ping)
        } catch {
            print("Failed to send ping: \(error.localizedDescription)")
            return false
        }
        
        do {
            let response = try await task?.receive()
            if case .string(let message) = response, !message.isEmpty {
                return true
            } else {
                print("Received empty pong.")
            }
        } catch {
            print("Failed to receive pong: \(error.localizedDescription)")
        }
        
        return false
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
        
        let isConnected = try await waitForConnection(timeout: 1)
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
        task?.cancel(with: .goingAway, reason: reason?.data(using: .utf8))
        
        try? await Task.sleep(for: .seconds(3))
        while task?.state == .canceling {
            await Task.yield()
            if Task.isCancelled { break }
        }
        
        task = nil
        state = .disconnected
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

// MARK: - Send & Receive
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

    
    func receive() async throws -> URLSessionWebSocketTask.Message {
        guard let task else { throw WebSocket.Error.connection(url: url, reason: .failed) }
        return try await task.receive()
    }
}

// MARK: - Receive Loop
extension WebSocket {
    private func startReceiveLoop() {
        receiveTask = Task {
            await self.receiveLoop()
        }
    }
    
    private func receiveLoop() async {
        guard let task else { return }
        
        while !Task.isCancelled {
            do {
                let message = try await task.receive()
                
                switch message {
                case .data(let data):
                    try await task.send(.data(data))
                case .string(let string):
                    try await task.send(.string(string))
                @unknown default:
                    throw Error.message(message: message, reason: .unsupported, description: "Unsupported message type: \(message)")
                }
            } catch {
                print("Receive loop encountered an error: \(error.localizedDescription)")
                await handleReceiveError(error)
                break
            }
        }
    }
    
    private func handleReceiveError(_ error: Swift.Error) async {
        state = .disconnected
        print("WebSocket (\(self.url.description)) is disconnected due to error.")
        try? await reconnect()
    }
}
