// Transport.State+Event.swift

import Foundation

extension SwiftFulcrum.Transport.State {
    public enum Event: Sendable {
        case connected(isReconnect: Bool)
        case disconnected(code: URLSessionWebSocketTask.CloseCode, reason: String?)
    }
}
