// Client.Error+ClientIssue.swift

import Foundation

extension SwiftFulcrum.Client.Error {
    public enum ClientIssue {
        case urlNotFound
        case invalidURL(String)
        case duplicateRegistration
        case cancelled
        case timeout(Duration)
        case invalidSubscriptionBufferCapacity(Int)
        case subscriptionUpdateBufferOverflow(Int)
        case emptyResponse(UUID?)
        case protocolMismatch(String?)
        case invalidProtocolNegotiationRange(
            minimumVersion: SwiftFulcrum.ProtocolVersion,
            maximumVersion: SwiftFulcrum.ProtocolVersion
        )
        case unknown(Swift.Error?)
    }
}

extension SwiftFulcrum.Client.Error.ClientIssue: Swift.Error, Equatable, Sendable {
    public static func == (lhs: SwiftFulcrum.Client.Error.ClientIssue, rhs: SwiftFulcrum.Client.Error.ClientIssue) -> Bool {
        switch (lhs, rhs) {
        case (.urlNotFound, .urlNotFound),
            (.duplicateRegistration, .duplicateRegistration),
            (.cancelled, .cancelled):
            return true
        case (.invalidURL(let leftURL), .invalidURL(let rightURL)):
            return leftURL == rightURL
        case (.timeout(let leftDuration), .timeout(let rightDuration)):
            return leftDuration == rightDuration
        case (.invalidSubscriptionBufferCapacity(let leftCapacity), .invalidSubscriptionBufferCapacity(let rightCapacity)):
            return leftCapacity == rightCapacity
        case (.subscriptionUpdateBufferOverflow(let leftCapacity), .subscriptionUpdateBufferOverflow(let rightCapacity)):
            return leftCapacity == rightCapacity
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
            return SwiftFulcrum.Client.Error.wrappedErrorsAreEqual(leftError, rightError)
        default:
            return false
        }
    }
}
