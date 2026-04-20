// Client.Error+Network.swift

import Foundation

extension SwiftFulcrum.Client.Error {
    public enum Network {
        case tlsNegotiationFailed(Swift.Error?)
    }
}

extension SwiftFulcrum.Client.Error.Network: Swift.Error, Equatable, Sendable {
    public static func == (lhs: SwiftFulcrum.Client.Error.Network, rhs: SwiftFulcrum.Client.Error.Network) -> Bool {
        switch (lhs, rhs) {
        case (.tlsNegotiationFailed(let leftError), .tlsNegotiationFailed(let rightError)):
            return SwiftFulcrum.Client.Error.wrappedErrorsAreEqual(leftError, rightError)
        }
    }
}
