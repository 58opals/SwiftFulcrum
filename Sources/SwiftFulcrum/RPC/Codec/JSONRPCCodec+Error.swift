// JSONRPCCodec+Error.swift

import Foundation

extension JSONRPCCodec {
    enum Error: Swift.Error {
        case rpc(SwiftFulcrum.RPC.Response.Error, methodPath: MethodPath, description: String)
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
