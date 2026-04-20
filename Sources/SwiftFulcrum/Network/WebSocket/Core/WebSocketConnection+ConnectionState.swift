// WebSocketConnection+ConnectionState.swift

import Foundation

extension WebSocketConnection {
    enum ConnectionState: Equatable {
        case idle
        case connecting
        case connected
        case disconnected
        case reconnecting
    }
}
