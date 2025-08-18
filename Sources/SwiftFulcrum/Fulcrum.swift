// Fulcrum.swift

import Foundation

public actor Fulcrum {
    let client: Client
    
    private(set) var isRunning = false
    
    public init(url: String? = nil) async throws {
        let webSocket = try await {
            if let urlString = url {
                guard let url = URL(string: urlString) else { throw Error.transport(.setupFailed) }
                guard ["ws", "wss"].contains(url.scheme?.lowercased()) else { throw Error.transport(.setupFailed) }
                return WebSocket(url: url)
            } else {
                //let serverList = try WebSocket.Server.getServerList()
                let serverList = try await Task.detached(priority: .utility) {
                    try await WebSocket.Server.getServerList()
                }.value
                guard let server = serverList.randomElement() else { throw Error.transport(.setupFailed) }
                return WebSocket(url: server)
            }
        }()
        
        self.client = .init(webSocket: webSocket)
    }
    
    init(servers: [URL]) throws {
        guard let server = servers.randomElement() else { throw Error.transport(.setupFailed) }
        self.client = .init(webSocket: WebSocket(url: server))
    }
    
    public func start() async throws {
        guard !self.isRunning else { return }
        
        try await self.client.start()
        self.isRunning = true
    }
    
    public func stop() async {
        guard self.isRunning else { return }
        self.isRunning = false
        
        await self.client.stop()
    }
    
    public func reconnect() async throws {
        guard self.isRunning else { return }
        try await self.client.reconnect()
    }
}
