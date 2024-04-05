import Foundation

extension WebSocket.Reconnector {
    struct Configuration {
        var maxReconnectionAttempts: Int
        var reconnectionDelay: TimeInterval
        
        static let defaultConfiguration = Self(maxReconnectionAttempts: 5,
                                               reconnectionDelay: 2.0)
    }
}
