import Foundation

extension SwiftFulcrum {
    public enum Error: Swift.Error {
        case networkError(underlyingError: Swift.Error)
        case decodingError(underlyingError: Swift.Error)
        case invalidURL
        case connectionClosed
        case customError(description: String)

        var localizedDescription: String {
            switch self {
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .invalidURL:
                return "Provided URL is invalid."
            case .connectionClosed:
                return "WebSocket connection was closed unexpectedly."
            case .customError(let description):
                return description
            }
        }
    }
}
