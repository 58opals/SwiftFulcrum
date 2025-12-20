// URLSessionWebSocketTask.Message+.swift

import Foundation

extension URLSessionWebSocketTask.Message {
    var dataPayload: Data? {
        switch self {
        case .data(let data):
            return data
        case .string(let string):
            return string.data(using: .utf8)
        @unknown default:
            return nil
        }
    }
}
