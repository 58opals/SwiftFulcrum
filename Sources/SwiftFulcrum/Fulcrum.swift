import Foundation

public struct Fulcrum {
    let client: Client
    public var subscriptionHub: SubscriptionHub
    
    public init(url: String? = nil) throws {
        let webSocket = try {
            if let urlString = url {
                guard let url = URL(string: urlString) else { throw WebSocket.Error.initializing(reason: .invalidURL, description: "URL: \(urlString)") }
                guard ["ws", "wss"].contains(url.scheme?.lowercased()) else { throw WebSocket.Error.initializing(reason: .unsupportedScheme, description: "URL: \(urlString)") }
                return WebSocket(url: url)
            } else {
                let serverList = try WebSocket.Server.getServerList()
                guard let server = serverList.randomElement() else { throw WebSocket.Error.initializing(reason: .noURLAvailable, description: "Server list: \(serverList)") }
                return WebSocket(url: server)
            }
        }()
        
        self.client = Client(webSocket: webSocket)
        self.subscriptionHub = SubscriptionHub()
    }
}
