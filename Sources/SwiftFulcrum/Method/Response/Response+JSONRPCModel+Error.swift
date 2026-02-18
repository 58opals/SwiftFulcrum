// Response+JSONRPCModel+Error.swift

import Foundation

extension Response.JSONRPCModel {
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

extension Response.JSONRPCModel.Error: Sendable {}
