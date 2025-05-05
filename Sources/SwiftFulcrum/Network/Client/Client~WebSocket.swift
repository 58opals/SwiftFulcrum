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
                    print("Giving up after \(attempt-1) failed reconnects – \(error)")
                    failAllPendingRequests(with: .connectionClosed)
                    break
                }
                
                print("Stream error: \(error) – attempting reconnect \(attempt)/\(ReconnectPolicy.maxAttempts) in \(delay)s")
                try? await Task.sleep(for: .seconds(delay))
                delay = min(delay * ReconnectPolicy.backoffFactor, ReconnectPolicy.maxDelay)
                
                do { try await webSocket.reconnect() }
                catch { print("Reconnect attempt failed: \(error)") }
            }
        }
    }
}
