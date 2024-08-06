import Foundation

extension Response.JSONRPCGeneric {
    enum JSONRPCResponseError: Swift.Error {
        case idIsMissing
        case errorIsMissing
        case resultIsMissing
        case methodIsMissing
        case paramsIsMissing
        
        case wrongResponseType
        case cannotIdentifyResponseType(UUID?)
    }
}
