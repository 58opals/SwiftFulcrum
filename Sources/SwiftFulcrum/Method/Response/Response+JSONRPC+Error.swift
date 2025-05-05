// Response+JSONRPC+Error.swift

import Foundation

extension Response.JSONRPC {
    enum Error: Swift.Error {
        case idIsMissing
        case errorIsMissing
        case resultIsMissing
        case methodIsMissing
        case paramsIsMissing
        
        case wrongResponseType
        case cannotIdentifyResponseType(UUID?)
    }
}
