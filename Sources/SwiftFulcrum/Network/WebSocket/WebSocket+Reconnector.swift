import Foundation

extension WebSocket {
    actor Reconnector {
        struct Configuration {
            var maxReconnectionAttempts: Int
            var reconnectionDelay: TimeInterval
            
            static let defaultConfiguration = Self(maxReconnectionAttempts: 3,
                                                   reconnectionDelay: 1.0)
        }
        
        private let configuration: Configuration
        private var reconnectionAttempts: Int
        
        init(_ configuration: Configuration, reconnectionAttempts: Int = 0) {
            self.configuration = configuration
            self.reconnectionAttempts = reconnectionAttempts
        }
        
        func resetReconnectionAttemptCount() {
            reconnectionAttempts = 0
            print("Reconnector reset: reconnectionAttempts = \(reconnectionAttempts)")
        }
        
        func attemptReconnection(for webSocket: WebSocket, with url: URL? = nil) async throws {
            while reconnectionAttempts < self.configuration.maxReconnectionAttempts {
                do {
                    let delay = min(pow(2.0, Double(self.reconnectionAttempts)) * self.configuration.reconnectionDelay, 120)
                    try await Task.sleep(for: .seconds(delay))
                    
                    reconnectionAttempts += 1
                    await webSocket.disconnect(with: "Reconnecting...")
                    await webSocket.createNewTask(with: url)
                    try await webSocket.connect()
                    
                    if await webSocket.isConnected {
                        resetReconnectionAttemptCount()
                        return
                    }
                } catch is CancellationError {
                    print("Reconnection cancelled.")
                    throw await WebSocket.Error.connection(url: webSocket.url, reason: .reconnectFailed)
                } catch {
                    print("Reconnection error: \(error)")
                }
            }
            
            throw WebSocket.Error.connection(url: await webSocket.url, reason: .maximumAttemptsReached)
        }
    }
}
