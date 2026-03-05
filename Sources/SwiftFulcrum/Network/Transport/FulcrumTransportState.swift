// FulcrumTransportState.swift

import Foundation

@available(*, deprecated, message: "Use SwiftFulcrum.Transport.State instead.")
public enum FulcrumTransportState {
    public enum EventModel: Sendable {
        case connected(isReconnect: Bool)
        case disconnected(code: URLSessionWebSocketTask.CloseCode, reason: String?)
    }
}
