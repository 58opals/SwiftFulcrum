// Response+Result+Error.swift

import Foundation

extension Response.Result {
    enum Error: Swift.Error {
        case missingField(String)
        case unexpectedFormat(String)
    }
}

extension Response.Result.Error: Equatable {}
