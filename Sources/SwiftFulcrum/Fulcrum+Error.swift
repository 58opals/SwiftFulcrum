// Fulcrum+Error.swift

import Foundation

extension Fulcrum {
    public enum Error: Swift.Error {
        case transport(Transport)
        case rpc(Server)
        case coding(Coding)
        case client(Client)
        
        public enum Network {
            case tlsNegotiationFailed(Swift.Error?)
        }
        
        public enum Transport {
            case setupFailed
            case connectionClosed(URLSessionWebSocketTask.CloseCode, String?)
            case network(Error.Network)
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
            case urlNotFound
            case duplicateHandler
            case cancelled
            case timeout(Duration)
            case emptyResponse(UUID?)
            case protocolMismatch(String?)
            case unknown(Swift.Error?)
        }
    }
}

extension Fulcrum.Error: Equatable, Sendable {}
extension Fulcrum.Error.Network: Swift.Error, Equatable, Sendable {
    public static func == (lhs: Fulcrum.Error.Network, rhs: Fulcrum.Error.Network) -> Bool {
        switch (lhs, rhs) {
        case (.tlsNegotiationFailed(let leftError), .tlsNegotiationFailed(let rightError)):
            return (leftError == nil && rightError == nil) || (leftError?.localizedDescription == rightError?.localizedDescription)
        }
    }
}
extension Fulcrum.Error.Transport: Swift.Error, Equatable, Sendable {}
extension Fulcrum.Error.Server: Swift.Error, Equatable, Sendable {}
extension Fulcrum.Error.Coding: Swift.Error, Equatable, Sendable {
    public static func == (lhs: Fulcrum.Error.Coding, rhs: Fulcrum.Error.Coding) -> Bool {
        switch (lhs, rhs) {
        case (.encode(let leftError), .encode(let rightError)):
            return (leftError == nil && rightError == nil) || (leftError?.localizedDescription == rightError?.localizedDescription)
        case (.decode(let leftError), .decode(let rightError)):
            return (leftError == nil && rightError == nil) || (leftError?.localizedDescription == rightError?.localizedDescription)
        default:
            return false
        }
    }
}
extension Fulcrum.Error.Client: Swift.Error, Equatable, Sendable {
    public static func == (lhs: Fulcrum.Error.Client, rhs: Fulcrum.Error.Client) -> Bool {
        switch (lhs, rhs) {
        case (.urlNotFound, .urlNotFound),
            (.duplicateHandler, .duplicateHandler),
            (.cancelled, .cancelled):
            return true
        case (.timeout(let leftDuration), .timeout(let rightDuration)):
            return leftDuration == rightDuration
        case (.emptyResponse(let leftUUID), .emptyResponse(let rightUUID)):
            return leftUUID == rightUUID
        case (.protocolMismatch(let leftMessage), .protocolMismatch(let rightMessage)):
            return leftMessage == rightMessage
        case (.unknown(let leftError), .unknown(let rightError)):
            return (leftError == nil && rightError == nil) || (leftError?.localizedDescription == rightError?.localizedDescription)
        default:
            return false
        }
    }
}

protocol FulcrumErrorConvertible: Swift.Error {
    var asFulcrumError: Fulcrum.Error { get }
}
