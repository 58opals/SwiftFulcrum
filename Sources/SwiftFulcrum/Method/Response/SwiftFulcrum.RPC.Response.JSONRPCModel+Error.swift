// SwiftFulcrum.RPC.Response+JSONRPCModel+Error.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPCModel {
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

extension SwiftFulcrum.RPC.Response.JSONRPCModel.Error: Sendable {}
