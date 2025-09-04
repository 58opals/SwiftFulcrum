// Fulcrum+Error.swift

import Foundation

extension Fulcrum {
    public enum Error: Swift.Error {
        case transport(Transport)
        case rpc(Server)
        case coding(Coding)
        case client(Client)
        
        public enum Transport {
            case setupFailed
            case connectionClosed(URLSessionWebSocketTask.CloseCode, String?)
            case network
            case reconnectFailed
            case heartbeatTimeout
        }
        
        public struct Server {
            public let id: UUID?
            public let code: Int
            public let message: String
        }
        
        public enum Coding {
            case encode(Swift.Error?)
            case decode(Swift.Error?)
        }
        
        public enum Client {
            case duplicateHandler
            case cancelled
            case emptyResponse(UUID?)
            case protocolMismatch(String?)
            case unknown(Swift.Error?)
        }
    }
}

extension Fulcrum.Error: Equatable, Sendable {}
extension Fulcrum.Error.Transport: Equatable, Sendable {}
extension Fulcrum.Error.Server: Equatable, Sendable {}
extension Fulcrum.Error.Coding: Equatable, Sendable {
    public static func == (lhs: Fulcrum.Error.Coding, rhs: Fulcrum.Error.Coding) -> Bool {
        switch (lhs, rhs) {
        case (.encode(let lErr), .encode(let rErr)):
            return (lErr == nil && rErr == nil) || (lErr?.localizedDescription == rErr?.localizedDescription)
        case (.decode(let lErr), .decode(let rErr)):
            return (lErr == nil && rErr == nil) || (lErr?.localizedDescription == rErr?.localizedDescription)
        default:
            return false
        }
    }
}
extension Fulcrum.Error.Client: Equatable, Sendable {
    public static func == (lhs: Fulcrum.Error.Client, rhs: Fulcrum.Error.Client) -> Bool {
        switch (lhs, rhs) {
        case (.duplicateHandler, .duplicateHandler),
            (.cancelled, .cancelled):
            return true
        case (.emptyResponse(let lUUID), .emptyResponse(let rUUID)):
            return lUUID == rUUID
        case (.protocolMismatch(let lMsg), .protocolMismatch(let rMsg)):
            return lMsg == rMsg
        case (.unknown(let lErr), .unknown(let rErr)):
            return (lErr == nil && rErr == nil) || (lErr?.localizedDescription == rErr?.localizedDescription)
        default:
            return false
        }
    }
}

protocol FulcrumErrorConvertible: Swift.Error {
    var asFulcrumError: Fulcrum.Error { get }
}
