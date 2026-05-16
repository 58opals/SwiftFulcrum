// Client.swift

import Foundation

/// Actor-based entry point for interacting with Fulcrum servers over WebSocket JSON-RPC.
///
/// Create an instance, use ``request(...)`` for unary requests or ``subscribe(...)`` for streaming
/// updates to lazily start the client when idle, and finish by invoking ``stop()`` to release
/// resources. Call ``start()`` only when you need to establish connectivity ahead of time.
extension SwiftFulcrum {
    public actor Client {
        let client: FulcrumNetworkClient

        private(set) var isRunning = false
        var desiredRunning = false
        var startTask: Task<Void, Swift.Error>?
        var startTaskWaiterCount = 0
        var currentConnectionState: ConnectionState = .idle
        var connectionStateObservationTask: Task<Void, Never>?
        var connectionStateContinuationsBySubscriberIdentifier: [UUID: AsyncStream<ConnectionState>.Continuation] = .init()

        /// Creates a Fulcrum client that connects to a specific server endpoint.
        /// - Parameters:
        ///   - endpoint: WebSocket endpoint for the Fulcrum server.
        ///   - configuration: Custom connection behavior including TLS, reconnection, catalog lookup, and protocol negotiation.
        /// - Throws: ``SwiftFulcrum.Client.Error`` when the transport cannot be prepared.
        public init(connectingTo endpoint: URL, configuration: Configuration = .init()) async throws {
            self.client = try Self.makeClient(connectingTo: endpoint, configuration: configuration)
            startConnectionStateObservation()
        }

        /// Creates a Fulcrum client that resolves a server from the configured catalog.
        /// - Parameter configuration: Custom connection behavior including catalog lookup, TLS, reconnection, and protocol negotiation.
        /// - Throws: ``SwiftFulcrum.Client.Error`` when no usable server can be loaded or the transport cannot be prepared.
        public init(configuration: Configuration = .init()) async throws {
            let endpoint = try await Self.selectServerEndpoint(using: configuration)
            self.client = try Self.makeClient(connectingTo: endpoint, configuration: configuration)
            startConnectionStateObservation()
        }

        init(client: FulcrumNetworkClient) async {
            self.client = client
            startConnectionStateObservation()
        }

        /// Establishes the WebSocketConnection connection and prepares automatic subscription restoration.
        ///
        /// This call is idempotent and safe to invoke from concurrent tasks. It suspends until the
        /// underlying socket is connected or fails. If ``stop()`` is called while ``start()`` is in
        /// flight, stop takes precedence and this method returns without leaving the client running.
        public func start() async throws {
            desiredRunning = true
            guard !self.isRunning else { return }

            let startTask = makeOrReuseStartTask()
            startTaskWaiterCount += 1
            defer {
                startTaskWaiterCount -= 1
                if Task.isCancelled, startTaskWaiterCount == 0 {
                    startTask.cancel()
                    self.startTask = nil
                }
            }

            do {
                try await awaitCancellableTask(startTask, cancelUnderlyingTask: false)
            } catch {
                if !desiredRunning, error is CancellationError {
                    return
                }
                if Task.isCancelled, error is CancellationError {
                    throw error
                }
                self.startTask = nil
                throw error
            }
            self.startTask = nil

            guard desiredRunning else { return }
            self.isRunning = true

            if connectionStateObservationTask == nil {
                startConnectionStateObservation()
            }
        }

        /// Cancels outstanding requests, closes the WebSocketConnection, and resets subscription state.
        ///
        /// This call is idempotent and deterministic. It cancels any in-flight ``start()`` and always
        /// performs teardown so the client is not left running.
        public func stop() async {
            let networkConnectionState = await client.connectionState
            let inFlightStartTask = startTask
            let shouldPreserveIdleState =
                !isRunning &&
                inFlightStartTask == nil &&
                currentConnectionState == .idle &&
                networkConnectionState == .idle

            desiredRunning = false
            self.isRunning = false

            if let inFlightStartTask {
                inFlightStartTask.cancel()
                self.startTask = nil
            }

            if shouldPreserveIdleState {
                await stopConnectionStateObservation()
            }

            await self.client.stop()
            if let inFlightStartTask {
                _ = try? await inFlightStartTask.value
            }
            desiredRunning = false

            if !shouldPreserveIdleState {
                await stopConnectionStateObservation()
            } else {
                currentConnectionState = .idle
            }
            await resetConnectionStateStream()
        }

        /// Forces a reconnect to the active or next available server while preserving subscription intent.
        ///
        /// Call this only after ``start()`` has succeeded. If the client is not running, this method
        /// throws a protocol mismatch error instead of returning silently. The call suspends while the
        /// reconnection attempt and subscription restore requests complete; cancelling the calling task
        /// cancels the in-flight reconnection. Successful restores remain active automatically, while a
        /// server-rejected restore terminates only the affected subscription stream.
        public func reconnect() async throws {
            guard self.isRunning else {
                throw SwiftFulcrum.Client.Error.client(
                    .protocolMismatch("reconnect() requires start() to succeed before reconnecting.")
                )
            }
            try await self.client.reconnect()
        }
    }
}

private extension SwiftFulcrum.Client {
    static func makeClient(connectingTo endpoint: URL, configuration: Configuration) throws -> FulcrumNetworkClient {
        let webSocket = try makeWebSocket(connectingTo: endpoint, configuration: configuration)

        return .init(
            transport: WebSocketTransport(webSocket: webSocket),
            protocolNegotiation: configuration.protocolNegotiation
        )
    }

    static func selectServerEndpoint(using configuration: Configuration) async throws -> URL {
        let serverList = try await configuration.serverCatalogLoader.loadServers(
            for: configuration.network,
            fallback: configuration.bootstrapServers ?? .init()
        )

        let validServers = serverList.compactMap { try? SwiftFulcrum.ServerCatalog.validate(endpoint: $0) }

        guard let server = validServers.randomElement() else {
            throw Error.transport(.setupFailed)
        }

        return server
    }

    static func makeWebSocket(connectingTo endpoint: URL, configuration: Configuration) throws -> WebSocketConnection {
        let endpoint = try SwiftFulcrum.ServerCatalog.validate(endpoint: endpoint)

        return WebSocketConnection(
            url: endpoint,
            configuration: configuration.convertToWebSocketConfiguration(),
            reconnectConfiguration: configuration.reconnect.reconnectorConfiguration,
            connectionTimeout: configuration.connectionTimeout
        )
    }

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
