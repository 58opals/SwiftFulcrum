// Response+ResultModel+Error.swift

import Foundation

extension Response.ResultModel {
    enum Error: Swift.Error {
        case missingField(String)
        case unexpectedFormat(String)
    }
}

extension Response.ResultModel.Error: Equatable {}
