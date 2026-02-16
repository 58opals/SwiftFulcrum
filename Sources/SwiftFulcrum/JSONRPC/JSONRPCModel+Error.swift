// JSONRPCModel+Error.swift

import Foundation

extension JSONRPCModel {
    enum Error: Swift.Error {
        case rpc(Response.Error, methodPath: MethodPath, description: String)
        case storage(StorageIssueModel, description: String)
        case decodingFailure(reason: DecodingFailureReasonModel, data: Data?, description: String)
        
        enum StorageIssueModel {
            case unknownMethodPath(String)
        }
        
        enum DecodingFailureReasonModel {
            case generic
            case idMissing
            case methodMissing
            case parametersMissing
            case errorMissing
            case unmatchedMethod(methodFromResponse: String, methodFromExtractor: String)
            case unexpectedFormat
        }
    }
}
