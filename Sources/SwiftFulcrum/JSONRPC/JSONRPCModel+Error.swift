// JSONRPCModel+Error.swift

import Foundation

extension JSONRPCModel {
    enum Error: Swift.Error {
        case rpc(FulcrumResponse.Error, methodPath: MethodPath, description: String)
        case storage(StorageIssue, description: String)
        case decodingFailure(reason: DecodingFailureReason, data: Data?, description: String)
        
        enum StorageIssue {
            case unknownMethodPath(String)
        }
        
        enum DecodingFailureReason {
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
