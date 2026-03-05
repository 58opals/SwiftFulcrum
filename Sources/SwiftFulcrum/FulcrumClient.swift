// FulcrumClient.swift

import Foundation

/// Actor-based entry point for interacting with Fulcrum servers over WebSocket JSON-RPC.
///
/// Create an instance, call ``start()`` to establish connectivity, use ``submit(...)`` for unary
/// requests or ``subscribe(...)`` for streaming updates, and finish by invoking ``stop()`` to
/// release resources.
@available(*, deprecated, message: "Use SwiftFulcrum.Client instead.")
public actor FulcrumClient {
    let client: FulcrumNetworkClient
    
    private(set) var isRunning = false
    var desiredRunning = false
    var startTask: Task<Void, Swift.Error>?
    var currentConnectionState: ConnectionState = .idle
    var connectionStateObservationTask: Task<Void, Never>?
    var connectionStateContinuationsBySubscriberIdentifier: [UUID: AsyncStream<ConnectionState>.Continuation] = .init()
    
    /// Creates a Fulcrum client.
    /// - Parameters:
    ///   - url: Optional WebSocket endpoint. When omitted, the client loads servers using
    ///     `configuration.serverCatalogLoader` for the configured network.
    ///   - configuration: Custom connection behavior including TLS, reconnection, metrics, and logging hooks.
    /// - Throws: ``FulcrumClient.Error`` when the transport cannot be prepared.
    public init(url: String? = nil, configuration: Configuration = .init()) async throws {
        let webSocket = try await {
            if let urlString = url {
                guard let url = URL(string: urlString) else { throw Error.transport(.setupFailed) }
                guard ["ws", "wss"].contains(url.scheme?.lowercased()) else { throw Error.transport(.setupFailed) }
                return WebSocketModel(
                    url: url,
                    configuration: configuration.convertToWebSocketConfiguration(),
                    reconnectConfiguration: configuration.reconnect.reconnectorConfiguration,
                    connectionTimeout: configuration.connectionTimeout
                )
            } else {
                let serverList = try await configuration.serverCatalogLoader.loadServers(
                    for: configuration.network,
                    fallback: configuration.bootstrapServers ?? .init()
                )
                guard let server = serverList.randomElement(),
                      ["ws", "wss"].contains(server.scheme?.lowercased()) else { throw Error.transport(.setupFailed) }
                return WebSocketModel(
                    url: server,
                    configuration: configuration.convertToWebSocketConfiguration(),
                    reconnectConfiguration: configuration.reconnect.reconnectorConfiguration,
                    connectionTimeout: configuration.connectionTimeout
                )
            }
        }()
        
        self.client = .init(transport: WebSocketTransportModel(webSocket: webSocket),
                            metrics: configuration.metrics,
                            logger: configuration.resolvedLogger,
                            protocolNegotiation: configuration.protocolNegotiation)
        startConnectionStateObservation()
    }
    
    init(servers: [URL], configuration: Configuration = .init()) async throws {
        guard let server = servers.randomElement(), ["ws", "wss"].contains(server.scheme?.lowercased()) else { throw Error.transport(.setupFailed) }
        self.client = .init(
            transport: WebSocketTransportModel(
                webSocket: WebSocketModel(
                    url: server,
                    configuration: configuration.convertToWebSocketConfiguration(),
                    reconnectConfiguration: configuration.reconnect.reconnectorConfiguration,
                    connectionTimeout: configuration.connectionTimeout
                )
            ),
            metrics: configuration.metrics,
            logger: configuration.resolvedLogger,
            protocolNegotiation: configuration.protocolNegotiation
        )
        startConnectionStateObservation()
    }
    
    init(client: FulcrumNetworkClient) async {
        self.client = client
        startConnectionStateObservation()
    }
    
    /// Establishes the WebSocketModel connection and prepares stream resubscription.
    ///
    /// This call is idempotent and safe to invoke from concurrent tasks. It suspends until the
    /// underlying socket is connected or fails. If ``stop()`` is called while ``start()`` is in
    /// flight, stop takes precedence and this method returns without leaving the client running.
    public func start() async throws {
        desiredRunning = true
        guard !self.isRunning else { return }
        
        let startTask = makeOrReuseStartTask()
        defer {
            self.startTask = nil
        }
        
        do {
            try await startTask.value
        } catch {
            if !desiredRunning, error is CancellationError {
                return
            }
            throw error
        }
        
        guard desiredRunning else { return }
        self.isRunning = true
        
        if connectionStateObservationTask == nil {
            startConnectionStateObservation()
        }
    }
    
    /// Cancels outstanding requests, closes the WebSocketModel, and resets subscription state.
    ///
    /// This call is idempotent and deterministic. It cancels any in-flight ``start()`` and always
    /// performs teardown so the client is not left running.
    public func stop() async {
        desiredRunning = false
        self.isRunning = false
        
        if let startTask {
            startTask.cancel()
            _ = try? await startTask.value
            self.startTask = nil
        }
        
        await self.client.stop()
        desiredRunning = false
        
        connectionStateObservationTask?.cancel()
        await connectionStateObservationTask?.value
        connectionStateObservationTask = nil
        await resetConnectionStateStream()
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

private extension FulcrumClient {
    func makeOrReuseStartTask() -> Task<Void, Swift.Error> {
        if let startTask {
            return startTask
        }
        
        let startTask = Task<Void, Swift.Error> { [client] in
            try await client.start()
        }
        self.startTask = startTask
        return startTask
    }
}
