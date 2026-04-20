// WebSocketConnection.Server+CodingKeys.swift

import Foundation

extension WebSocketConnection.Server {
    enum CodingKeys: String, CodingKey {
        case host
        case port
        case scheme
        case url
    }
}
