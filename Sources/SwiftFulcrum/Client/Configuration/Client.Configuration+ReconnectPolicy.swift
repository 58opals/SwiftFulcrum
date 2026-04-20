// Client.Configuration+ReconnectPolicy.swift

import Foundation

extension SwiftFulcrum.Client.Configuration {
    public struct ReconnectPolicy: Sendable {
        public var maximumReconnectionAttempts: Int
        public var reconnectionDelay: TimeInterval
        public var maximumDelay: TimeInterval
        public var jitterRange: ClosedRange<TimeInterval>

        public var isUnlimited: Bool { maximumReconnectionAttempts <= 0 }

        public static let basic = Self(
            maximumReconnectionAttempts: 1,
            reconnectionDelay: 1.5,
            maximumDelay: 30,
            jitterRange: 0.8 ... 1.3
        )

        public init(
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

extension SwiftFulcrum.Client.Configuration.ReconnectPolicy {
    var reconnectorConfiguration: WebSocketConnection.Reconnector.Configuration {
        .init(
            maximumReconnectionAttempts: maximumReconnectionAttempts,
            reconnectionDelay: reconnectionDelay,
            maximumDelay: maximumDelay,
            jitterRange: jitterRange
        )
    }
}
