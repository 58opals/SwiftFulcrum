// JSONRPCCodec.Error+DecodingFailureReason.swift

import Foundation

extension JSONRPCCodec.Error {
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
