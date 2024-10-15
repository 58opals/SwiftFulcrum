import Foundation

extension WebSocket {
    enum Error: Swift.Error {
        case initializing(reason: InitializingIssue, description: String)
        case connection(url: URL, reason: ConnectionIssue)
        case message(message: URLSessionWebSocketTask.Message, reason: MessageIssue, description: String)
        
        enum InitializingIssue {
            case invalidURL
            case unsupportedScheme
            case noURLAvailable
            case cannotGetServerList
        }
        
        enum ConnectionIssue {
            case failed
            case alreadyConnected
            case maximumAttemptsReached
            case reconnectFailed
            case unknown
        }
        
        enum MessageIssue {
            case invalid
            case encoding
            case decoding
        }
    }
}
