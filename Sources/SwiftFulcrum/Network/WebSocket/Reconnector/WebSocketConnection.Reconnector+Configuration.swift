// WebSocketConnection.Reconnector+Configuration.swift

import Foundation

extension WebSocketConnection.Reconnector {
    struct Configuration: Sendable {
        var maximumReconnectionAttempts: Int
        var reconnectionDelay: TimeInterval
        var maximumDelay: TimeInterval
        var jitterRange: ClosedRange<TimeInterval>

        var isUnlimited: Bool { maximumReconnectionAttempts <= 0 }

        static let basic = Self(
            maximumReconnectionAttempts: 1,
            reconnectionDelay: 1.5,
            maximumDelay: 30,
            jitterRange: 0.8 ... 1.3
        )

        init(
            maximumReconnectionAttempts: Int,
            reconnectionDelay: TimeInterval,
            maximumDelay: TimeInterval,
            jitterRange: ClosedRange<TimeInterval>
        ) {
            self.maximumReconnectionAttempts = maximumReconnectionAttempts
            self.reconnectionDelay = reconnectionDelay
            self.maximumDelay = maximumDelay
            self.jitterRange = jitterRange
        }
    }
}
