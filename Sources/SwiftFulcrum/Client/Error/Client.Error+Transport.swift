// Client.Error+Transport.swift

import Foundation

extension SwiftFulcrum.Client.Error {
    public enum Transport {
        case setupFailed
        case connectionClosed(URLSessionWebSocketTask.CloseCode, String?)
        case network(SwiftFulcrum.Client.Error.Network)
        case reconnectFailed
        case heartbeatTimeout
    }
}

extension SwiftFulcrum.Client.Error.Transport: Swift.Error, Equatable, Sendable {
    public static func == (lhs: SwiftFulcrum.Client.Error.Transport, rhs: SwiftFulcrum.Client.Error.Transport) -> Bool {
        switch (lhs, rhs) {
        case (.setupFailed, .setupFailed),
            (.reconnectFailed, .reconnectFailed),
            (.heartbeatTimeout, .heartbeatTimeout):
            return true
        case (.connectionClosed(let leftCode, let leftReason), .connectionClosed(let rightCode, let rightReason)):
            return leftCode.rawValue == rightCode.rawValue && leftReason == rightReason
        case (.network(let leftError), .network(let rightError)):
            return leftError == rightError
        default:
            return false
        }
    }
}
