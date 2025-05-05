// Client+Error.swift

import Foundation

extension Client {
    enum Error: Swift.Error {
        case requestCancelled
        case requestFailure(type: RequestType)
        case encodingFailed
        case decodingFailed
        case duplicateHandler
        
        case transport(Transport)
        case server(RPC)
        
        enum RequestType {
            case regular
            case subscription
        }
        
        enum Transport {
            case connectionClosed(URLSessionWebSocketTask.CloseCode, String?)
            case network(Swift.Error)
            case decoding(Swift.Error)
        }
        
        struct RPC: Swift.Error, Sendable, Equatable {
            public let id: UUID?
            public let code: Int
            public let message: String
        }
    }
}
