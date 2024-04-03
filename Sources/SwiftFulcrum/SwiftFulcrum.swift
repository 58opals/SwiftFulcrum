import Foundation

public struct SwiftFulcrum {
    let storage: Storage
    let client: Client
    
    public init() throws {
        let servers = WebSocket.Server.samples
        guard let server = servers.randomElement() else { throw WebSocket.Error.initializing(reason: .noURLAvailable, description: "Server list: \(servers)") }
        let websocket = WebSocket(url: server)
        
        self.storage = Storage()
        self.client = Client(webSocket: websocket, storage: storage)
    }
    
    public init(urlString: String) throws {
        guard let url = URL(string: urlString) else { throw WebSocket.Error.initializing(reason: .invalidURL, description: "URL: \(urlString)") }
        let websocket = WebSocket(url: url)
        
        self.storage = Storage()
        self.client = Client(webSocket: websocket, storage: storage)
    }
}
