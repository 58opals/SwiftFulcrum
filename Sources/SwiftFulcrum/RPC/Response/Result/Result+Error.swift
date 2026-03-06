// Result+Error.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result {
    enum Error: Swift.Error {
        case missingField(String)
        case unexpectedFormat(String)
    }
}

extension SwiftFulcrum.RPC.Response.Result.Error: Equatable {}
