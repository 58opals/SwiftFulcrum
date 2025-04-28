// Client+Error.swift

import Foundation

extension Client {
    enum Error: Swift.Error {
        enum RequestType {
            case regular
            case subscription
        }
        
        case requestFailure(type: RequestType)
        case encodingFailed
        case duplicateHandler
    }
}
