// Client.swift

import Foundation

actor Client {
    let id: UUID
    let transport: Transportable
    var jsonRPC: JSONRPC
    let router: Router
    let metrics: MetricsCollectable?
    let logger: Log.Handler
    let protocolNegotiation: Fulcrum.Configuration.ProtocolNegotiation
    
    var state: State
    
    var subscriptionMethods: [SubscriptionKey: Method]
    
    var receiveTask: Task<Void, Never>?
    private var lifecycleTask: Task<Void, Never>?
    private var diagnosticsStateTask: Task<Void, Never>?
    
    var rpcHeartbeatTask: Task<Void, Never>?
    let rpcHeartbeatInterval: Duration
    let rpcHeartbeatTimeout: Duration
    
    var connectionState: Fulcrum.ConnectionState { get async { await transport.connectionState } }
    
    init(transport: Transportable,
         metrics: MetricsCollectable? = nil,
         logger: Log.Handler? = nil,
         heartbeatInterval: Duration = .seconds(25),
         heartbeatTimeout: Duration = .seconds(10),
         protocolNegotiation: Fulcrum.Configuration.ProtocolNegotiation) {
        self.id = .init()
        self.transport = transport
        self.jsonRPC = .init()
        self.router = .init()
        self.metrics = metrics
        self.subscriptionMethods = .init()
        self.logger = logger ?? Log.ConsoleHandler()
        self.protocolNegotiation = protocolNegotiation
        self.state = .init()
        self.rpcHeartbeatInterval = heartbeatInterval
        self.rpcHeartbeatTimeout = heartbeatTimeout
        if let metrics { Task { await self.transport.updateMetrics(metrics) } }
        Task { await self.transport.updateLogger(self.logger) }
    }
    
    func start() async throws {
        resetNegotiatedSession()
        
        guard receiveTask == nil else { return }
        
        try await self.transport.connect()
        startReceivingTask()
        startLifecycleObservationTasks()
        
        _ = try await ensureNegotiatedProtocol()
        
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
        resetNegotiatedSession()
    }
    
    func reconnect(with url: URL? = nil) async throws {
        receiveTask?.cancel()
        await receiveTask?.value
        receiveTask = nil
        lifecycleTask?.cancel()
        await lifecycleTask?.value
        lifecycleTask = nil
        diagnosticsStateTask?.cancel()
        await diagnosticsStateTask?.value
        diagnosticsStateTask = nil
        resetNegotiatedSession()
        try await transport.reconnect(with: url)
        startReceivingTask()
        startLifecycleObservationTasks()
        await publishDiagnosticsSnapshot()
    }
    
    func makeConnectionStateEvents() async -> AsyncStream<Fulcrum.ConnectionState> {
        await transport.makeConnectionStateEvents()
    }
    
    private func startReceivingTask() {
        receiveTask = Task { await self.startReceiving() }
    }
    
    private func startLifecycleObservationTasks() {
        lifecycleTask?.cancel()
        lifecycleTask = Task { [weak self] in
            guard let self else { return }
            for await event in await self.transport.makeLifecycleEvents() {
                await self.publishDiagnosticsSnapshot()
                switch event {
                case .connected(let isReconnect) where isReconnect:
                    await self.resetNegotiatedSession()
                    await self.emitLog(.info, "client.autoresubscribe.begin")
                    do {
                        _ = try await self.ensureNegotiatedProtocol()
                        await self.resubscribeStoredMethods()
                        await self.emitLog(.info,
                                           "client.autoresubscribe.end",
                                           metadata: ["count": String(self.subscriptionMethods.count)])
                    } catch {
                        await self.emitLog(.error,
                                           "client.protocol_negotiation.failed",
                                           metadata: ["error": error.localizedDescription])
                    }
                case .disconnected:
                    await self.resetNegotiatedSession()
                default: break
                }
            }
        }
        
        diagnosticsStateTask?.cancel()
        diagnosticsStateTask = Task { [weak self] in
            guard let self else { return }
            let stream = await self.transport.makeConnectionStateEvents()
            for await _ in stream {
                await self.publishDiagnosticsSnapshot()
            }
        }
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
