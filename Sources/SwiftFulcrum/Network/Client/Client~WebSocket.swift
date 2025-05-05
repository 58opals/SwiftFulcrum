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
    func startReceiving() async {
        while !Task.isCancelled {
            do {
                for try await message in await webSocket.messages() {
                    await webSocket.reconnector.resetReconnectionAttemptCount()
                    await handleMessage(message)
                }
                break
            } catch {
                print("WebSocket stream error: \(error). Delegating reconnect...")
                
                do {
                    try await webSocket.reconnect()
                } catch {
                    print("Reconnect failed: \(error) - terminating receive loop.")
                    failAllPendingRequests(with: .connectionClosed)
                    break
                }
            }
        }
    }
}
