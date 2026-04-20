// Client+Error.swift

import Foundation

extension SwiftFulcrum.Client {
    public enum Error: Swift.Error {
        case transport(Transport)
        case rpc(Server)
        case coding(Coding)
        case client(ClientIssue)
    }
}

extension SwiftFulcrum.Client.Error: Equatable, Sendable {}

extension SwiftFulcrum.Client.Error {
    static func wrappedErrorsAreEqual(_ lhs: Swift.Error?, _ rhs: Swift.Error?) -> Bool {
        switch (wrappedErrorIdentity(lhs), wrappedErrorIdentity(rhs)) {
        case (nil, nil):
            return true
        case let ((leftType, leftDomain, leftCode)?, (rightType, rightDomain, rightCode)?):
            return leftType == rightType
                && leftDomain == rightDomain
                && leftCode == rightCode
        default:
            return false
        }
    }

    static func wrappedErrorIdentity(_ error: Swift.Error?) -> (String, String, Int)? {
        guard let error else { return nil }

        let nsError = error as NSError
        return (
            String(reflecting: type(of: error)),
            nsError.domain,
            nsError.code
        )
    }
}
