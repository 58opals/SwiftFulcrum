import Foundation

extension WebSocket {
    class Reconnector {
        private let configuration: Configuration
        private var reconnectionAttempts: Int
        
        init(_ configuration: Configuration, reconnectionAttempts: Int = 0) {
            self.configuration = configuration
            self.reconnectionAttempts = reconnectionAttempts
        }
        
        func attemptReconnection(for webSocket: WebSocket) async throws {
            guard !webSocket.isConnected else { throw WebSocket.Error.connection(url: webSocket.url, reason: .alreadyConnected) }
            if reconnectionAttempts < self.configuration.maxReconnectionAttempts {
                let delay = min(pow(2.0, Double(self.reconnectionAttempts)) * self.configuration.reconnectionDelay, 120)
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
