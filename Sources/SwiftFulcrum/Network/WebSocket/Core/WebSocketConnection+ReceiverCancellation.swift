// WebSocketConnection+ReceiverCancellation.swift

import Foundation

extension WebSocketConnection {
    enum ReceiverCancellation: Sendable {
        case cancel
        case preserve
    }
}
