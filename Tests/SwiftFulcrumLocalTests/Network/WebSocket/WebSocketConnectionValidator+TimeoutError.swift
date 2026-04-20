// WebSocketConnectionValidator+TimeoutError.swift

import Foundation

extension WebSocketConnectionValidator {
    enum TimeoutError: Swift.Error {
        case missingSocketTask
    }
}
