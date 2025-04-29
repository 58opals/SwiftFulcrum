// Client~WebSocket.swift

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
    /// Controls delay and attempt limits for reconnection.
    struct ReconnectPolicy {
        static let initialDelay: TimeInterval = 1  // seconds
        static let backoffFactor: Double      = 2
        static let maxDelay: TimeInterval     = 32 // seconds
        static let maxAttempts: UInt          = 5  // per disconnection
    }
    
    func startReceiving() async {
        var attempt: UInt       = 0
        var delay: TimeInterval = ReconnectPolicy.initialDelay
        
        while !Task.isCancelled {
            do {
                for try await message in await webSocket.messages() {
                    await handleMessage(message)
                }
                break
            } catch {
                attempt += 1
                guard attempt <= ReconnectPolicy.maxAttempts else {
                    print("🛑 Giving up after \(attempt-1) failed reconnects – \(error)")
                    failAllPendingRequests(with: .connectionClosed)
                    break
                }
                
                print("⚡️ Stream error: \(error) – attempting reconnect \(attempt)/\(ReconnectPolicy.maxAttempts) in \(delay)s")
                try? await Task.sleep(for: .seconds(delay))
                delay = min(delay * ReconnectPolicy.backoffFactor, ReconnectPolicy.maxDelay)
                
                do { try await webSocket.reconnect() }
                catch { print("🔄 Reconnect attempt failed: \(error)") }
            }
        }
    }
    
    private func observeMessages() async {
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
    
    private enum Inbound {
        private struct RPCErrorEnvelope: Decodable { let id: UUID?; let error: Response.Error.Result }
        static func serverError(from data: Data) -> Client.Failure? {
            guard let envelope = try? JSONDecoder().decode(RPCErrorEnvelope.self, from: data) else { return nil }
            let rpc = RPCError(id: envelope.id, code: envelope.error.code, message: envelope.error.message)
            return .server(rpc)
        }
    }
    func handleData(_ data: Data) async {
        do {
            let identifier = try Response.JSONRPC.extractIdentifier(from: data)
            switch identifier {
            case .uuid(let identifier):
                if let handler = regularResponseHandlers[identifier] {
                    if let fail = Inbound.serverError(from: data) {
                        handler(.failure(fail))
                    } else {
                        handler(.success(data))
                    }
                    removeRegularResponseHandler(for: identifier)
                } else {
                    print("No handler for regular response identifier: \(identifier)")
                }
            case .string(let methodPath):
                let identifier = identifierFromNotification(methodPath: methodPath, data: data)
                let key        = SubscriptionKey(methodPath: methodPath, identifier: identifier)
                
                if let handler = subscriptionResponseHandlers[key] {
                    if let fail = Inbound.serverError(from: data) {
                        handler(.failure(fail))
                        removeSubscriptionResponseHandler(for: key)
                    } else {
                        handler(.success(data))
                    }
                } else {
                    print("No subscription handler for \(key)")
                }
            }
        } catch {
            print("Failed to decode response: \(error)")
        }
    }
}
