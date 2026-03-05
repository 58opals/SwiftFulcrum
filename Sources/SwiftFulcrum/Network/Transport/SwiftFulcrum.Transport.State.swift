// SwiftFulcrum.Transport.State.swift

import Foundation

public extension SwiftFulcrum.Transport {
    enum State {
        public enum EventModel: Sendable {
            case connected(isReconnect: Bool)
            case disconnected(code: URLSessionWebSocketTask.CloseCode, reason: String?)
        }
    }
}
