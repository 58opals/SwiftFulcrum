// Fulcrum.swift

import Foundation

public actor Fulcrum {
    let client: Client
    
    private(set) var isRunning = false
    
    public init(url: String? = nil, configuration: Configuration = .init()) async throws {
        let webSocket = try await {
            if let urlString = url {
                guard let url = URL(string: urlString) else { throw Error.transport(.setupFailed) }
                guard ["ws", "wss"].contains(url.scheme?.lowercased()) else { throw Error.transport(.setupFailed) }
                return WebSocket(
                    url: url,
                    configuration: configuration.convertToWebSocketConfiguration(),
                    reconnectConfiguration: configuration.reconnect,
                    connectionTimeout: configuration.connectionTimeout
                )
            } else {
                let serverList = try await Task.detached(priority: .utility) {
                    try await WebSocket.Server.getServerList()
                }.value
                guard let server = serverList.randomElement() else { throw Error.transport(.setupFailed) }
                return WebSocket(
                    url: server,
                    configuration: configuration.convertToWebSocketConfiguration(),
                    reconnectConfiguration: configuration.reconnect,
                    connectionTimeout: configuration.connectionTimeout
                )
            }
        }()
        
        self.client = .init(webSocket: webSocket, metrics: configuration.metrics, logger: configuration.logger)
    }
    
    init(servers: [URL], configuration: Configuration = .init()) throws {
        guard let server = servers.randomElement(), ["ws", "wss"].contains(server.scheme?.lowercased()) else { throw Error.transport(.setupFailed) }
        self.client = .init(
            webSocket: WebSocket(
                url: server,
                configuration: configuration.convertToWebSocketConfiguration(),
                reconnectConfiguration: configuration.reconnect,
                connectionTimeout: configuration.connectionTimeout
            ),
            metrics: configuration.metrics,
            logger: configuration.logger
        )
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
