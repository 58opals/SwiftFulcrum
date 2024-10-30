import Foundation

extension Client {
    func send(data: Data) async throws {
        try await webSocket.send(data: data)
    }
    
    func send(string: String) async throws {
        try await webSocket.send(string: string)
    }
}

extension Client {
    func receiveLoop() async {
        while true {
            do {
                let message = try await webSocket.receive()
                await handleMessage(message)
            } catch {
                print("Receive loop encountered an error: \(error.localizedDescription)")
                try? await webSocket.reconnect()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

extension Client {
    func handleMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .data(let data):
            await self.handleData(data)
        case .string(let string):
            if let data = string.data(using: .utf8) { await self.handleData(data) }
            else { print("Failed to convert string message to Data.") }
        @unknown default:
            print("Unknown message type")
        }
    }
    
    func handleData(_ data: Data) async {
        do {
            let identifier = try Response.JSONRPC.extractIdentifier(from: data)
            switch identifier {
            case .uuid(let uuid):
                if let handler = regularResponseHandlers[uuid] {
                    try handler(data)
                    regularResponseHandlers.removeValue(forKey: uuid)
                } else {
                    print("No handler for regular response identifier: \(uuid)")
                }
            case .string(let string):
                if let handler = subscriptionResponseHandlers[string] {
                    try handler(data)
                    //subscriptionResponseHandlers.removeValue(forKey: string)
                } else {
                    print("No handler for subscription response identifier: \(string)")
                }
            }
        } catch {
            print("Failed to decode response: \(error)")
        }
    }
}
