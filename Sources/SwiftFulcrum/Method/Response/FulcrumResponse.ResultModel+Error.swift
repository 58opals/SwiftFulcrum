// FulcrumResponse+ResultModel+Error.swift

import Foundation

extension FulcrumResponse.ResultModel {
    enum Error: Swift.Error {
        case missingField(String)
        case unexpectedFormat(String)
    }
}

extension FulcrumResponse.ResultModel.Error: Equatable {}
