// WebSocket+ConnectionState.swift

import Foundation

extension WebSocket {
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
    }
}
