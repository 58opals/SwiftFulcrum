// WebSocket+Reconnector.swift

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
                let delay = min(pow(2.0, Double(reconnectionAttempts)) * self.configuration.reconnectionDelay, 120)
                print("Reconnection attempt \(reconnectionAttempts + 1) in \(delay) seconds...")
                try await Task.sleep(for: .seconds(delay))
                
                reconnectionAttempts += 1
                print("Attempting to reconnect (\(reconnectionAttempts))...")
                
                do {
                    await webSocket.cancelReceiverTask()
                    if let newURL = url { await webSocket.setURL(newURL) }
                    try await webSocket.connect()
                    
                    if await webSocket.isConnected {
                        resetReconnectionAttemptCount()
                        print("Reconnected successfully.")
                        return
                    }
                } catch {
                    print("Reconnection attempt \(reconnectionAttempts) failed: \(error.localizedDescription)")
                }
            }
            
            print("Maximum reconnection attempts reached.")
            throw await WebSocket.Error.connection(url: webSocket.url, reason: .maximumAttemptsReached)
        }
    }
}
