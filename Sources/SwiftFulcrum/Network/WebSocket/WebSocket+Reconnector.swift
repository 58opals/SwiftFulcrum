// WebSocket+Reconnector.swift

import Foundation

extension WebSocket {
    public actor Reconnector {
        public struct Configuration: Sendable {
            public var maximumReconnectionAttempts: Int
            public var reconnectionDelay: TimeInterval
            public var maximumDelay: TimeInterval
            public var jitterRange: ClosedRange<TimeInterval>
            
            public var isUnlimited: Bool { maximumReconnectionAttempts <= 0 }
            
            public static let basic = Self(maximumReconnectionAttempts: 0,
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
        
        func attemptReconnection(
            for webSocket: WebSocket,
            with url: URL? = nil,
            cancelReceiver: Bool = true
        ) async throws {
            while configuration.isUnlimited || reconnectionAttempts < configuration.maximumReconnectionAttempts {
                let base = pow(2.0, Double(reconnectionAttempts)) * configuration.reconnectionDelay
                let delay = min(base, configuration.maximumDelay) * .random(in: configuration.jitterRange)
                try await Task.sleep(for: .seconds(delay))
                
                reconnectionAttempts += 1
                await webSocket.emitLog(.info, "reconnect.attempt",
                                        metadata: ["attempt": String(reconnectionAttempts),
                                                   "unlimited": String(configuration.isUnlimited)])
                
                do {
                    if cancelReceiver { await webSocket.cancelReceiverTask() }
                    if let url { await webSocket.setURL(url) }
                    try await webSocket.connect(withEmitLifecycle: false)
                    resetReconnectionAttemptCount()
                    await webSocket.ensureAutoReceive()
                    try await webSocket.connect(withEmitLifecycle: true)
                    await webSocket.emitLog(.info, "reconnect.succeeded")
                    await webSocket.emitLifecycle(.connected(isReconnect: true))
                    return
                } catch {
                    await webSocket.emitLog(.warning, "reconnect.failed",
                                            metadata: ["attempt": String(reconnectionAttempts),
                                                       "error": (error as NSError).localizedDescription])
                }
            }
            
            await webSocket.emitLog(.error, "reconnect.max_attempts_reached")
            throw await Fulcrum.Error.transport(.connectionClosed(webSocket.closeInformation.code,
                                                                  webSocket.closeInformation.reason))
        }
    }
}
