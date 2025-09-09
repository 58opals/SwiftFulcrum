// WebSocket+Reconnector.swift

import Foundation

extension WebSocket {
    public actor Reconnector {
        public struct Configuration: Sendable {
            public var maximumReconnectionAttempts: Int
            public var reconnectionDelay: TimeInterval
            public var maximumDelay: TimeInterval
            public var jitterRange: ClosedRange<TimeInterval>
            
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
        
        public init(_ configuration: Configuration, reconnectionAttempts: Int = 0) {
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
                await webSocket.emitLog(.info,
                                                        "reconnect.attempt",
                                                        metadata: ["attempt": String(reconnectionAttempts)])
                                 
                
                do {
                    await webSocket.cancelReceiverTask()
                    await webSocket.createNewTask(with: url)
                    try await webSocket.connect()
                    resetReconnectionAttemptCount()
                    await webSocket.emitLog(.info, "reconnect.succeeded")
                    return
                } catch {
                    await webSocket.emitLog(.warning,
                                                                "reconnect.failed",
                                                                metadata: ["attempt": String(reconnectionAttempts),
                                                                           "error": (error as NSError).localizedDescription])
                                     
                }
            }
            
            await webSocket.emitLog(.error, "reconnect.max_attempts_reached")
            throw await Fulcrum.Error.transport(.connectionClosed(webSocket.closeInformation.code, webSocket.closeInformation.reason))
        }
    }
}
