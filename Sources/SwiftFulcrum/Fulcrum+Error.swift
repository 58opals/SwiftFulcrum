// Fulcrum+Error.swift

import Foundation

extension Fulcrum {
    public enum Error: Swift.Error {
        case network(underlyingError: Swift.Error)
        case decoding(underlyingError: Swift.Error)
        case invalidURL(description: String)
        case connectionClosed
        case resultNotFound(description: String)
        case resultTypeMismatch(description: String)
        case custom(description: String)
        case serverError(code: Int, message: String)

        var localizedDescription: String {
            switch self {
            case .network(let error):
                return "Network error: \(error.localizedDescription)"
            case .decoding(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .invalidURL(let description):
                return "Invalid URL: \(description)"
            case .connectionClosed:
                return "WebSocket connection was closed unexpectedly."
            case .resultNotFound(let description):
                return "Result not found: \(description)"
            case .resultTypeMismatch(let description):
                return "Result type mismatch: \(description)"
            case .custom(let description):
                return description
            case .serverError(let code, let message):
                return "Server error \(code): \(message)"
            }
        }
    }
}

extension Fulcrum.Error: Equatable {
    public static func == (lhs: Fulcrum.Error, rhs: Fulcrum.Error) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}
