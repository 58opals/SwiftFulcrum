import Foundation

extension WebSocket {
    class Reconnector {
        private var reconnectionAttempts = 0
        private let maxReconnectionAttempts = 5
        private let reconnectionDelay = 2.0 // seconds
        
        func attemptReconnection(for webSocket: WebSocket) async throws {
            guard !webSocket.isConnected else { throw WebSocket.Error.connection(url: webSocket.url, reason: .alreadyConnected) }
            if reconnectionAttempts < maxReconnectionAttempts {
                let delay = min(pow(2.0, Double(reconnectionAttempts)) * reconnectionDelay, 120)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                reconnectionAttempts += 1
                webSocket.disconnect(with: "Reconnecting...")
                webSocket.connect()
            } else {
                throw WebSocket.Error.connection(url: webSocket.url, reason: .maximumAttemptsReached)
            }
        }
    }
}
