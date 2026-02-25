// FulcrumNetworkClient.swift

import Foundation

actor FulcrumNetworkClient {
    let id: UUID
    let transport: TransportableModel
    var jsonRPC: JSONRPCModel
    let router: Router
    let metrics: MetricsClient?
    let logger: LogModel.HandlerModel
    let protocolNegotiation: FulcrumClient.Configuration.ProtocolNegotiationModel
    
    var state: State
    
    var subscriptionMethods: [SubscriptionKeyModel: FulcrumMethodRequest]
    
    var receiveTask: Task<Void, Never>?
    private var lifecycleTask: Task<Void, Never>?
    private var diagnosticsStateTask: Task<Void, Never>?
    
    var rpcHeartbeatTask: Task<Void, Never>?
    let rpcHeartbeatInterval: Duration
    let rpcHeartbeatTimeout: Duration
    
    var connectionState: FulcrumClient.ConnectionState { get async { await transport.connectionState } }
    
    init(transport: TransportableModel,
         metrics: MetricsClient? = nil,
         logger: LogModel.HandlerModel? = nil,
         heartbeatInterval: Duration = .seconds(25),
         heartbeatTimeout: Duration = .seconds(10),
         protocolNegotiation: FulcrumClient.Configuration.ProtocolNegotiationModel) {
        self.id = .init()
        self.transport = transport
        self.jsonRPC = .init()
        self.router = .init()
        self.metrics = metrics
        self.subscriptionMethods = .init()
        self.logger = logger ?? LogModel.ConsoleHandlerModel()
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
        
        do {
            _ = try await ensureNegotiatedProtocol()
            
            startRPCHeartbeat()
            await publishDiagnosticsSnapshot()
        } catch {
            await cancelBackgroundTasks()
            await transport.disconnect(with: "FulcrumNetworkClient.start() negotiation failed")
            throw error
        }
    }
    
    func stop() async {
        let info = await transport.closeInformation
        let closedError = await FulcrumClient.Error.transport(.connectionClosed(info.code, info.reason))
        let inflightCount = await router.failAll(with: closedError)
        await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
        
        await stopRPCHeartbeat()
        await cancelBackgroundTasks()
        await transport.disconnect(with: "FulcrumNetworkClient.stop() called")
        resetNegotiatedSession()
    }
    
    func reconnect(with url: URL? = nil) async throws {
        await cancelBackgroundTasks()
        resetNegotiatedSession()
        try await transport.reconnect(with: url)
        startReceivingTask()
        
        do {
            _ = try await ensureNegotiatedProtocol()
            emitLog(.info, "client.reconnect_resubscribe.begin")
            await resubscribeStoredMethods()
            emitLog(.info,
                    "client.reconnect_resubscribe.end",
                    metadata: ["count": String(subscriptionMethods.count)])
            startLifecycleObservationTasks()
            await publishDiagnosticsSnapshot()
        } catch {
            await cancelBackgroundTasks()
            await transport.disconnect(with: "FulcrumNetworkClient.reconnect() negotiation failed")
            throw error
        }
    }
    
    func makeConnectionStateEvents() async -> AsyncStream<FulcrumClient.ConnectionState> {
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
    
    private func cancelAndNil(_ task: Task<Void, Never>?) async -> Task<Void, Never>? {
        guard let task else { return nil }
        task.cancel()
        await task.value
        return nil
    }
    
    private func cancelBackgroundTasks() async {
        receiveTask = await cancelAndNil(receiveTask)
        lifecycleTask = await cancelAndNil(lifecycleTask)
        diagnosticsStateTask = await cancelAndNil(diagnosticsStateTask)
    }
}

extension FulcrumNetworkClient {
    func emitLog(
        _ level: LogModel.LevelModel,
        _ message: @autoclosure () -> String,
        metadata: [String: String] = .init(),
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) {
        var mergedMetadata = ["component": "FulcrumNetworkClient", "client_id": id.uuidString]
        mergedMetadata.merge(metadata, uniquingKeysWith: { _, new in new })
        logger.log(level, message(), metadata: mergedMetadata, file: file, function: function, line: line)
    }
}
