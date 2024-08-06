import Foundation
import Network
import Combine

final class WebSocket {
    var url: URL
    
    private var task: URLSessionWebSocketTask
    let receivedData: PassthroughSubject<Data, Never> = PassthroughSubject<Data, Never>()
    let receivedString: PassthroughSubject<String, Never> = PassthroughSubject<String, Never>()
    
    var isConnected: Bool = false
    let reconnector: Reconnector
    
    init(url: URL, reconnectConfiguration: Reconnector.Configuration = .defaultConfiguration) {
        self.url = url
        self.task = URLSession.shared.webSocketTask(with: url)
        self.reconnector = Reconnector(reconnectConfiguration)
    }
}

extension WebSocket {
    func connect() {
        task.resume()
        isConnected = true
        print("WebSocket (\(self.url.description)) is connected.")
        
        Task {
            try await listen()
        }
    }
    
    func disconnect(with reason: String? = nil) {
        task.cancel(with: .goingAway, reason: reason?.data(using: .utf8))
        isConnected = false
        print("WebSocket (\(self.url.description)) is disconnected.")
    }
    
    func reconnect(with url: URL? = nil) async throws {
        try await reconnector.attemptReconnection(for: self, with: url)
    }
    
    func createNewTask(with url: URL? = nil) {
        if let newURL = url { self.url = newURL }
        self.task = URLSession.shared.webSocketTask(with: self.url)
    }
}

extension WebSocket {
    func send(data: Data) async throws {
        let message = URLSessionWebSocketTask.Message.data(data)
        try await task.send(message)
    }
    
    func send(string: String) async throws {
        let message = URLSessionWebSocketTask.Message.string(string)
        try await task.send(message)
    }
    
    func receive() async throws -> URLSessionWebSocketTask.Message {
        let message = try await task.receive()
        return message
    }
    
    func listen() async throws {
        while isConnected {
            do {
                switch task.state {
                case .running:
                    let message = try await self.receive()
                    try self.publish(message: message)
                    
                case .suspended:
                    await Task.yield()
                    
                case .canceling:
                    isConnected = false
                    print("The task is canceling.")
                    return
                    
                case .completed:
                    isConnected = false
                    print("The task is completed.")
                    return
                    
                @unknown default:
                    break
                }
            } catch let error as NWError where error == .posix(.ENOTCONN) {
                print(error.debugDescription)
                isConnected = false
                try await self.reconnect()
            } catch {
                throw error
            }
        }
    }
}

extension WebSocket {
    func publish(message: URLSessionWebSocketTask.Message) throws {
        switch message {
        case .data(let data):
            receivedData.send(data)
        case .string(let string):
            receivedString.send(string)
        default:
            throw Error.message(message: message, reason: .invalid, description: "The type of the message is not valid.")
        }
    }
}
