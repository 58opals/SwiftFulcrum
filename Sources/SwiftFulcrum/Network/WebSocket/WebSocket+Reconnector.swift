// WebSocket+Reconnector.swift

import Foundation

extension WebSocket {
    public actor Reconnector {
        public struct Configuration: Sendable {
            var maximumReconnectionAttempts: Int
            var reconnectionDelay: TimeInterval
            var maximumDelay: TimeInterval
            var jitterRange: ClosedRange<TimeInterval>
            
            public static let defaultConfiguration = Self(maximumReconnectionAttempts: 3,
                                                          reconnectionDelay: 1.0,
                                                          maximumDelay: 30,
                                                          jitterRange: 0.8 ... 1.3)
            
            public init(maximumReconnectionAttempts: Int,
                        reconnectionDelay: TimeInterval,
                        maximumDelay: TimeInterval,
                        jitterRange: ClosedRange<TimeInterval>) {
                self.maximumReconnectionAttempts = maximumReconnectionAttempts
                self.reconnectionDelay = reconnectionDelay
                self.maximumDelay = maximumDelay
                self.jitterRange = jitterRange
            }
        }
        
        private let configuration: Configuration
        private var reconnectionAttempts: Int
        
        init(_ configuration: Configuration, reconnectionAttempts: Int = 0) {
            self.configuration = configuration
            self.reconnectionAttempts = reconnectionAttempts
        }
        
        func resetReconnectionAttemptCount() {
            reconnectionAttempts = 0
        }
        
        func attemptReconnection(for webSocket: WebSocket, with url: URL? = nil) async throws {
            while reconnectionAttempts < self.configuration.maximumReconnectionAttempts {
                let base = pow(2.0, Double(reconnectionAttempts)) * self.configuration.reconnectionDelay
                let delay = min(base, self.configuration.maximumDelay) * .random(in: self.configuration.jitterRange)
                try await Task.sleep(for: .seconds(delay))
                
                reconnectionAttempts += 1
                print("Attempting to reconnect (\(reconnectionAttempts))...")
                
                do {
                    await webSocket.cancelReceiverTask()
                    await webSocket.createNewTask(with: url)
                    try await webSocket.connect()
                    resetReconnectionAttemptCount()
                    print("Reconnected successfully.")
                    return
                } catch {
                    print("Reconnection attempt \(reconnectionAttempts) failed: \(error.localizedDescription)")
                }
            }
            
            print("Maximum reconnection attempts reached.")
            throw await Fulcrum.Error.transport(.connectionClosed(webSocket.closeInformation.code, webSocket.closeInformation.reason))
        }
    }
}
