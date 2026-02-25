// FulcrumResponse+JSONRPCModel+Error.swift

import Foundation

extension FulcrumResponse.JSONRPCModel {
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

extension FulcrumResponse.JSONRPCModel.Error: Sendable {}
