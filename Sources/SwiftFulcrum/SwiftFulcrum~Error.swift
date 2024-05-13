import Foundation

extension SwiftFulcrum {
    public enum Error: Swift.Error {
        case network(underlyingError: Swift.Error)
        case decoding(underlyingError: Swift.Error)
        case invalidURL
        case connectionClosed
        case resultNotFound
        case resultTypeMismatch
        case custom(description: String)

        var localizedDescription: String {
            switch self {
            case .network(let error):
                return "Network error: \(error.localizedDescription)"
            case .decoding(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .invalidURL:
                return "Provided URL is invalid."
            case .connectionClosed:
                return "WebSocket connection was closed unexpectedly."
            case .resultNotFound:
                return "Result not found."
            case .resultTypeMismatch:
                return "Result type isn't matched."
            case .custom(let description):
                return description
            }
        }
    }
}
