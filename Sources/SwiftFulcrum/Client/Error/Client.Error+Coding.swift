// Client.Error+Coding.swift

import Foundation

extension SwiftFulcrum.Client.Error {
    public enum Coding {
        case encode(Swift.Error?)
        case decode(Swift.Error?)
    }
}

extension SwiftFulcrum.Client.Error.Coding: Swift.Error, Equatable, Sendable {
    public static func == (lhs: SwiftFulcrum.Client.Error.Coding, rhs: SwiftFulcrum.Client.Error.Coding) -> Bool {
        switch (lhs, rhs) {
        case (.encode(let leftError), .encode(let rightError)):
            return SwiftFulcrum.Client.Error.wrappedErrorsAreEqual(leftError, rightError)
        case (.decode(let leftError), .decode(let rightError)):
            return SwiftFulcrum.Client.Error.wrappedErrorsAreEqual(leftError, rightError)
        default:
            return false
        }
    }
}
