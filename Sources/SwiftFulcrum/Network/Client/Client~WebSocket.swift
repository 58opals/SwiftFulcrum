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
    func observeMessages() async {
        do {
            for try await message in await webSocket.messages() {
                await handleMessage(message)
            }
            
            print("WebSocket stream ended.")
        } catch {
            print("Stream ended with error: \(error.localizedDescription)")
            
            do {
                try await webSocket.reconnect()
                try? await Task.sleep(for: .seconds(1))
                await observeMessages()
            } catch {
                print("Reconnection failed: \(error.localizedDescription)")
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
            case .uuid(let identifier):
                if let handler = regularResponseHandlers[identifier] {
                    handler(.success(data))
                    removeRegularResponseHandler(for: identifier)
                } else {
                    print("No handler for regular response identifier: \(identifier)")
                }
            case .string(let identifier):
                if let handler = subscriptionResponseHandlers[identifier] {
                    handler(.success(data))
                    removeSubscriptionResponseHandler(for: identifier)
                } else {
                    print("No handler for subscription response identifier: \(identifier)")
                }
            }
        } catch {
            print("Failed to decode response: \(error)")
        }
    }
}
