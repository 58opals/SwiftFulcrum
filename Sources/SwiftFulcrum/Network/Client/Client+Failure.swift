// Client+Failure.swift

import Foundation

extension Client {
    /// What the handler will now receive on `.failure(…)`.
    public enum Failure: Swift.Error {
        case transport(TransportError)
        case server(RPCError)
    }
    /// Transport-level fault: WebSocket closed, timeout, JSON decode blew up…
    public enum TransportError: Swift.Error {
        case connectionClosed(URLSessionWebSocketTask.CloseCode, String?)
        case network(Swift.Error)
        case decoding(Swift.Error)
    }

    /// The server replied with an `error` object per JSON-RPC 2.0.
    public struct RPCError: Swift.Error, Sendable, Equatable {
        public let id: UUID?
        public let code: Int
        public let message: String
    }
}
