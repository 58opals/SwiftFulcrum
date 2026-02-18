// FulcrumClient+Error.swift

import Foundation

extension FulcrumClient {
    public enum Error: Swift.Error {
        case transport(TransportModel)
        case rpc(ServerModel)
        case coding(CodingModel)
        case client(Client)
        
        public enum NetworkModel {
            case tlsNegotiationFailed(Swift.Error?)
        }
        
        public enum TransportModel {
            case setupFailed
            case connectionClosed(URLSessionWebSocketTask.CloseCode, String?)
            case network(Error.NetworkModel)
            case reconnectFailed
            case heartbeatTimeout
        }
        
        public struct ServerModel {
            public let id: UUID?
            public let code: Int
            public let message: String
        }
        
        public enum CodingModel {
            case encode(Swift.Error?)
            case decode(Swift.Error?)
        }
        
        public enum Client {
            case urlNotFound
            case invalidURL(String)
            case duplicateHandler
            case cancelled
            case timeout(Duration)
            case emptyResponse(UUID?)
            case protocolMismatch(String?)
            case unknown(Swift.Error?)
        }
    }
}

extension FulcrumClient.Error: Equatable, Sendable {}
extension FulcrumClient.Error.NetworkModel: Swift.Error, Equatable, Sendable {
    public static func == (lhs: FulcrumClient.Error.NetworkModel, rhs: FulcrumClient.Error.NetworkModel) -> Bool {
        switch (lhs, rhs) {
        case (.tlsNegotiationFailed(let leftError), .tlsNegotiationFailed(let rightError)):
            return (leftError == nil && rightError == nil) || (leftError?.localizedDescription == rightError?.localizedDescription)
        }
    }
}
extension FulcrumClient.Error.TransportModel: Swift.Error, Equatable, Sendable {
    public static func == (lhs: FulcrumClient.Error.TransportModel, rhs: FulcrumClient.Error.TransportModel) -> Bool {
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
extension FulcrumClient.Error.ServerModel: Swift.Error, Equatable, Sendable {}
extension FulcrumClient.Error.CodingModel: Swift.Error, Equatable, Sendable {
    public static func == (lhs: FulcrumClient.Error.CodingModel, rhs: FulcrumClient.Error.CodingModel) -> Bool {
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
extension FulcrumClient.Error.Client: Swift.Error, Equatable, Sendable {
    public static func == (lhs: FulcrumClient.Error.Client, rhs: FulcrumClient.Error.Client) -> Bool {
        switch (lhs, rhs) {
        case (.urlNotFound, .urlNotFound),
            (.duplicateHandler, .duplicateHandler),
            (.cancelled, .cancelled):
            return true
        case (.invalidURL(let leftURL), .invalidURL(let rightURL)):
            return leftURL == rightURL
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

protocol FulcrumErrorConvertibleModel: Swift.Error {
    var asFulcrumError: FulcrumClient.Error { get }
}
