// Fulcrum.swift

import Foundation

/// Actor-based entry point for interacting with Fulcrum servers over WebSocket RPC.
///
/// Create an instance, call ``start()`` to establish connectivity, use ``submit(...)`` for unary
/// requests or ``subscribe(...)`` for streaming updates, and finish by invoking ``stop()`` to
/// release resources.
public actor Fulcrum {
    let client: Client
    
    private(set) var isRunning = false
    var currentConnectionState: ConnectionState = .idle
    var connectionStateObservationTask: Task<Void, Never>?
    var sharedConnectionStateStream: AsyncStream<ConnectionState>?
    var connectionStateContinuation: AsyncStream<ConnectionState>.Continuation?
    
    /// Creates a Fulcrum client.
    /// - Parameters:
    ///   - url: Optional WebSocket endpoint. When omitted, the client downloads bundled server catalogs for the configured network.
    ///   - configuration: Custom connection behavior including TLS, reconnection, metrics, and logging hooks.
    /// - Throws: ``Fulcrum.Error`` when the transport cannot be prepared.
    public init(url: String? = nil, configuration: Configuration = .init()) async throws {
        let webSocket = try await {
            if let urlString = url {
                guard let url = URL(string: urlString) else { throw Error.transport(.setupFailed) }
                guard ["ws", "wss"].contains(url.scheme?.lowercased()) else { throw Error.transport(.setupFailed) }
                return WebSocket(
                    url: url,
                    configuration: configuration.convertToWebSocketConfiguration(),
                    reconnectConfiguration: configuration.reconnect.reconnectorConfiguration,
                    connectionTimeout: configuration.connectionTimeout
                )
            } else {
                let serverList = try await Task.detached(priority: .utility) {
                    try await WebSocket.Server.fetchServerList(
                        for: configuration.network,
                        fallback: configuration.bootstrapServers ?? .init()
                    )
                }.value
                guard let server = serverList.randomElement() else { throw Error.transport(.setupFailed) }
                return WebSocket(
                    url: server,
                    configuration: configuration.convertToWebSocketConfiguration(),
                    reconnectConfiguration: configuration.reconnect.reconnectorConfiguration,
                    connectionTimeout: configuration.connectionTimeout
                )
            }
        }()
        
        self.client = .init(transport: WebSocketTransport(webSocket: webSocket),
                            metrics: configuration.metrics,
                            logger: configuration.logger)
        startConnectionStateObservation()
    }
    
    init(servers: [URL], configuration: Configuration = .init()) async throws {
        guard let server = servers.randomElement(), ["ws", "wss"].contains(server.scheme?.lowercased()) else { throw Error.transport(.setupFailed) }
        self.client = .init(
            transport: WebSocketTransport(
                webSocket: WebSocket(
                    url: server,
                    configuration: configuration.convertToWebSocketConfiguration(),
                    reconnectConfiguration: configuration.reconnect.reconnectorConfiguration,
                    connectionTimeout: configuration.connectionTimeout
                )
            ),
            metrics: configuration.metrics,
            logger: configuration.logger
        )
        startConnectionStateObservation()
    }
    
    init(client: Client) async {
        self.client = client
        startConnectionStateObservation()
    }
    
    /// Establishes the WebSocket connection and prepares stream resubscription.
    ///
    /// This call is idempotent and safe to invoke from concurrent tasks. It suspends until the
    /// underlying socket is connected or fails. Cancellation of the calling task propagates to
    /// the connection attempt.
    public func start() async throws {
        guard !self.isRunning else { return }
        
        try await self.client.start()
        self.isRunning = true
    }
    
    /// Cancels outstanding requests, closes the WebSocket, and resets subscription state.
    ///
    /// The shutdown is best-effort when the calling task is cancelled. Invoke ``stop()`` from
    /// a separate task if you need teardown to complete after a caller is cancelled.
    public func stop() async {
        guard self.isRunning else { return }
        self.isRunning = false
        
        await self.client.stop()
    }
    
    /// Forces a reconnect to the active or next available server while preserving subscription intents.
    ///
    /// Only callable after ``start()`` has succeeded. The call suspends while the reconnection attempt
    /// completes; cancelling the calling task cancels the in-flight reconnection.
    public func reconnect() async throws {
        guard self.isRunning else { return }
        try await self.client.reconnect()
    }
}
