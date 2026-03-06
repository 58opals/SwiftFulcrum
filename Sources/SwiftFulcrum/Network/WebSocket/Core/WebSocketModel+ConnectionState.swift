import Foundation

extension WebSocketModel {
    enum ConnectionState: Equatable {
        case idle
        case connecting
        case connected
        case disconnected
        case reconnecting
    }
}
