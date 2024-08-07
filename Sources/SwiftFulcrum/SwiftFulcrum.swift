import Foundation
import Combine

public struct SwiftFulcrum {
    let client: Client
    var subscribers: Set<AnyCancellable>
    
    public init(url: String? = nil) throws {
        let webSocket = try {
            if let urlString = url {
                guard let url = URL(string: urlString) else { throw WebSocket.Error.initializing(reason: .invalidURL, description: "URL: \(urlString)") }
                guard ["ws", "wss"].contains(url.scheme?.lowercased()) else { throw WebSocket.Error.initializing(reason: .unsupportedScheme, description: "URL: \(urlString)") }
                return WebSocket(url: url)
            } else {
                let servers = WebSocket.Server.samples
                guard let server = servers.randomElement() else { throw WebSocket.Error.initializing(reason: .noURLAvailable, description: "Server list: \(servers)") }
                return WebSocket(url: server)
            }
        }()
        
        self.client = Client(webSocket: webSocket)
        self.subscribers = Set<AnyCancellable>()
    }
}
