// Fulcrum.swift

import Foundation

public actor Fulcrum {
    let client: Client
    
    private(set) var isRunning = false
    
    public init(url: String? = nil) throws {
        let webSocket = try {
            if let urlString = url {
                guard let url = URL(string: urlString) else { throw Error.transport(.setupFailed) }
                guard ["ws", "wss"].contains(url.scheme?.lowercased()) else { throw Error.transport(.setupFailed) }
                return WebSocket(url: url)
            } else {
                let serverList = try WebSocket.Server.getServerList()
                guard let server = serverList.randomElement() else { throw Error.transport(.setupFailed) }
                return WebSocket(url: server)
            }
        }()
        
        self.client = .init(webSocket: webSocket)
    }
    
    public func start() async throws {
        try await self.client.start()
        self.isRunning = true
    }
    
    public func stop() async {
        guard self.isRunning else { return }
        self.isRunning = false
        
        await self.client.stop()
    }
}
