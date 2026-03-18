// Client+Error.swift

import Foundation

extension SwiftFulcrum.Client {
    public enum Error: Swift.Error {
        case transport(TransportModel)
        case rpc(Server)
        case coding(CodingModel)
        case client(ClientIssue)
        
        public enum Network {
            case tlsNegotiationFailed(Swift.Error?)
        }
        
        public enum TransportModel {
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
        
        public enum CodingModel {
            case encode(Swift.Error?)
            case decode(Swift.Error?)
        }
        
        public enum ClientIssue {
            case urlNotFound
            case invalidURL(String)
            case duplicateHandler
            case cancelled
            case timeout(Duration)
            case emptyResponse(UUID?)
            case protocolMismatch(String?)
            case invalidProtocolNegotiationRange(
                minimumVersion: SwiftFulcrum.ProtocolVersion,
                maximumVersion: SwiftFulcrum.ProtocolVersion
            )
            case unknown(Swift.Error?)
        }
    }
}

extension SwiftFulcrum.Client.Error: Equatable, Sendable {}
extension SwiftFulcrum.Client.Error.Network: Swift.Error, Equatable, Sendable {
    public static func == (lhs: SwiftFulcrum.Client.Error.Network, rhs: SwiftFulcrum.Client.Error.Network) -> Bool {
        switch (lhs, rhs) {
        case (.tlsNegotiationFailed(let leftError), .tlsNegotiationFailed(let rightError)):
            return wrappedErrorsAreEqual(leftError, rightError)
        }
    }
}
extension SwiftFulcrum.Client.Error.TransportModel: Swift.Error, Equatable, Sendable {
    public static func == (lhs: SwiftFulcrum.Client.Error.TransportModel, rhs: SwiftFulcrum.Client.Error.TransportModel) -> Bool {
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
extension SwiftFulcrum.Client.Error.Server: Swift.Error, Equatable, Sendable {}
extension SwiftFulcrum.Client.Error.CodingModel: Swift.Error, Equatable, Sendable {
    public static func == (lhs: SwiftFulcrum.Client.Error.CodingModel, rhs: SwiftFulcrum.Client.Error.CodingModel) -> Bool {
        switch (lhs, rhs) {
        case (.encode(let leftError), .encode(let rightError)):
            return wrappedErrorsAreEqual(leftError, rightError)
        case (.decode(let leftError), .decode(let rightError)):
            return wrappedErrorsAreEqual(leftError, rightError)
        default:
            return false
        }
    }
}
extension SwiftFulcrum.Client.Error.ClientIssue: Swift.Error, Equatable, Sendable {
    public static func == (lhs: SwiftFulcrum.Client.Error.ClientIssue, rhs: SwiftFulcrum.Client.Error.ClientIssue) -> Bool {
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
        case (
            .invalidProtocolNegotiationRange(
                minimumVersion: let leftMinimum,
                maximumVersion: let leftMaximum
            ),
            .invalidProtocolNegotiationRange(
                minimumVersion: let rightMinimum,
                maximumVersion: let rightMaximum
            )
        ):
            return leftMinimum == rightMinimum && leftMaximum == rightMaximum
        case (.unknown(let leftError), .unknown(let rightError)):
            return wrappedErrorsAreEqual(leftError, rightError)
        default:
            return false
        }
    }
}

private func wrappedErrorsAreEqual(_ lhs: Swift.Error?, _ rhs: Swift.Error?) -> Bool {
    wrappedErrorIdentity(lhs) == wrappedErrorIdentity(rhs)
}

private func wrappedErrorIdentity(_ error: Swift.Error?) -> WrappedErrorIdentity? {
    guard let error else { return nil }

    let nsError = error as NSError
    return WrappedErrorIdentity(
        typeName: String(reflecting: type(of: error)),
        domain: nsError.domain,
        code: nsError.code
    )
}

private struct WrappedErrorIdentity: Equatable {
    let typeName: String
    let domain: String
    let code: Int
}
