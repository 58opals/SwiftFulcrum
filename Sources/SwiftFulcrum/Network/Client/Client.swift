// Client.swift

import Foundation

actor Client {
    let id: UUID
    let transport: Transportable
    var jsonRPC: JSONRPC
    let router: Router
    let metrics: MetricsCollectable?
    let logger: Log.Handler
    
    var subscriptionMethods: [SubscriptionKey: Method]
    
    private var receiveTask: Task<Void, Never>?
    private var lifecycleTask: Task<Void, Never>?
    private var diagnosticsStateTask: Task<Void, Never>?
    
    var rpcHeartbeatTask: Task<Void, Never>?
    let rpcHeartbeatInterval: Duration = .seconds(25)
    let rpcHeartbeatTimeout: Duration = .seconds(10)
    
    var connectionState: Fulcrum.ConnectionState { get async { await transport.connectionState } }
    
    init(transport: Transportable, metrics: MetricsCollectable? = nil, logger: Log.Handler? = nil) {
        self.id = .init()
        self.transport = transport
        self.jsonRPC = .init()
        self.router = .init()
        self.metrics = metrics
        self.subscriptionMethods = .init()
        self.logger = logger ?? Log.ConsoleHandler()
        if let metrics { Task { await self.transport.updateMetrics(metrics) } }
        Task { await self.transport.updateLogger(self.logger) }
    }
    
    func start() async throws {
        guard receiveTask == nil else { return }
        
        try await self.transport.connect()
        self.receiveTask = Task { await self.startReceiving() }
        self.lifecycleTask = Task { [weak self] in
            guard let self else { return }
            for await event in await self.transport.makeLifecycleEvents() {
                await self.publishDiagnosticsSnapshot()
                switch event {
                case .connected(let isReconnect) where isReconnect:
                    await self.emitLog(.info, "client.autoresubscribe.begin")
                    await self.resubscribeStoredMethods()
                    await self.emitLog(.info, "client.autoresubscribe.end", metadata: ["count": String(await self.subscriptionMethods.count)])
                default: break
                }
            }
        }
        
        self.diagnosticsStateTask = Task { [weak self] in
            guard let self else { return }
            let stream = await self.transport.makeConnectionStateEvents()
            for await _ in stream {
                await self.publishDiagnosticsSnapshot()
            }
        }
        
        startRPCHeartbeat()
        await publishDiagnosticsSnapshot()
    }
    
    func stop() async {
        let info = await transport.closeInformation
        let closedError = await Fulcrum.Error.transport(.connectionClosed(info.code, info.reason))
        let inflightCount = await router.failAll(with: closedError)
        await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
        
        await stopRPCHeartbeat()
        
        receiveTask?.cancel()
        await receiveTask?.value
        receiveTask = nil
        
        lifecycleTask?.cancel()
        await lifecycleTask?.value
        lifecycleTask = nil
        
        diagnosticsStateTask?.cancel()
        await diagnosticsStateTask?.value
        diagnosticsStateTask = nil
        
        await transport.disconnect(with: "Client.stop() called")
    }
    
    func reconnect(with url: URL? = nil) async throws {
        receiveTask?.cancel()
        await receiveTask?.value
        receiveTask = nil
        try await transport.reconnect(with: url)
        receiveTask = Task { await self.startReceiving() }
        await publishDiagnosticsSnapshot()
    }
    
    func makeConnectionStateEvents() async -> AsyncStream<Fulcrum.ConnectionState> {
        await transport.makeConnectionStateEvents()
    }
}

extension Client {
    func emitLog(
        _ level: Log.Level,
        _ message: @autoclosure () -> String,
        metadata: [String: String] = .init(),
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) {
        var mergedMetadata = ["component": "Client", "client_id": id.uuidString]
        mergedMetadata.merge(metadata, uniquingKeysWith: { _, new in new })
        logger.log(level, message(), metadata: mergedMetadata, file: file, function: function, line: line)
    }
}
