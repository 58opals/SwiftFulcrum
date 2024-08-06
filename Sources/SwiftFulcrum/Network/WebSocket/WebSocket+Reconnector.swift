import Foundation

extension WebSocket {
    class Reconnector {
        struct Configuration {
            var maxReconnectionAttempts: Int
            var reconnectionDelay: TimeInterval
            
            static let defaultConfiguration = Self(maxReconnectionAttempts: 5,
                                                   reconnectionDelay: 2.0)
        }
        
        private let configuration: Configuration
        private var reconnectionAttempts: Int
        
        init(_ configuration: Configuration, reconnectionAttempts: Int = 0) {
            self.configuration = configuration
            self.reconnectionAttempts = reconnectionAttempts
        }
        
        func attemptReconnection(for webSocket: WebSocket, with url: URL? = nil) async throws {
            guard !webSocket.isConnected else { throw WebSocket.Error.connection(url: webSocket.url, reason: .alreadyConnected) }
            if reconnectionAttempts < self.configuration.maxReconnectionAttempts {
                let delay = min(pow(2.0, Double(self.reconnectionAttempts)) * self.configuration.reconnectionDelay, 120)
                try await Task.sleep(for: .seconds(delay * 1))
                reconnectionAttempts += 1
                webSocket.disconnect(with: "Reconnecting...")
                webSocket.createNewTask(with: url)
                webSocket.connect()
            } else {
                throw WebSocket.Error.connection(url: webSocket.url, reason: .maximumAttemptsReached)
            }
        }
    }
}
