// FulcrumTransportState.swift

import Foundation

public enum FulcrumTransportState {
    public enum EventModel: Sendable {
        case connected(isReconnect: Bool)
        case disconnected(code: URLSessionWebSocketTask.CloseCode, reason: String?)
    }
}
