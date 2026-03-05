// SwiftFulcrum.RPC.Response+ResultModel+Error.swift

import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel {
    enum Error: Swift.Error {
        case missingField(String)
        case unexpectedFormat(String)
    }
}

extension SwiftFulcrum.RPC.Response.ResultModel.Error: Equatable {}
