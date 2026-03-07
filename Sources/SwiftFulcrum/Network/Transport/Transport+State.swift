// Transport+State.swift

import Foundation

extension SwiftFulcrum.Transport {
    public enum State {
        public enum Event: Sendable {
            case connected(isReconnect: Bool)
            case disconnected(code: URLSessionWebSocketTask.CloseCode, reason: String?)
        }
    }
}
