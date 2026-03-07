// JSONRPCResponseDecodeError.swift

import Foundation

enum JSONRPCResponseDecodeError: Swift.Error, Sendable {
    case wrongResponseType
    case cannotIdentifyResponseType(UUID?)
}
