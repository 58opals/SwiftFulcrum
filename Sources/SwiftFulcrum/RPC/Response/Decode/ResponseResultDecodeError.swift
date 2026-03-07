// ResponseResultDecodeError.swift

import Foundation

enum ResponseResultDecodeError: Swift.Error, Equatable, Sendable {
    case missingField(String)
    case unexpectedFormat(String)
}
