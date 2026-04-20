// FulcrumNetworkClient.swift

import Foundation

actor FulcrumNetworkClient {
    let id: UUID
    let transport: TransportAdapter
    var jsonRPC: JSONRPCCodec
    let router: Router
    let metrics: SwiftFulcrum.Metrics.MetricsClient?
    let logger: SwiftFulcrum.Logging.Adapter
    let protocolNegotiation: SwiftFulcrum.Client.Configuration.ProtocolNegotiation
    
    var state: State
    
    var subscriptionMethods: [SubscriptionKey: SwiftFulcrum.RPC.Method]
    var activeSubscriptionRequestIdentifiers: [SubscriptionKey: UUID]
    var pendingSubscriptionRequestIdentifiers: [SubscriptionKey: UUID]
    var subscriptionCancellationRegistrations: [SubscriptionKey: SubscriptionCancellationRegistration]
    var subscriptionCleanupTasks: [SubscriptionKey: Task<Bool, Never>]
    var subscriptionSetupRequestIdentifiers: [SubscriptionKey: UUID]
    var subscriptionSetupTasks: [SubscriptionKey: Task<Void, Swift.Error>]
    
    var receiveTask: Task<Void, Never>?
    private var startupTask: Task<Void, Swift.Error>?
    private var reconnectTask: Task<Void, Swift.Error>?
    private var lifecycleTask: Task<Void, Never>?
    private var diagnosticsStateTask: Task<Void, Never>?
    
    var rpcHeartbeatTask: Task<Void, Never>?
    let rpcHeartbeatInterval: Duration
    let rpcHeartbeatTimeout: Duration
    
    var connectionState: SwiftFulcrum.Client.ConnectionState { get async { await transport.connectionState } }
    
    init(transport: TransportAdapter,
         metrics: SwiftFulcrum.Metrics.MetricsClient? = nil,
         logger: SwiftFulcrum.Logging.Adapter? = nil,
         heartbeatInterval: Duration = .seconds(25),
         heartbeatTimeout: Duration = .seconds(10),
         protocolNegotiation: SwiftFulcrum.Client.Configuration.ProtocolNegotiation) {
        self.id = .init()
        self.transport = transport
        self.jsonRPC = .init()
        self.router = .init()
        self.metrics = metrics
        self.subscriptionMethods = .init()
        self.activeSubscriptionRequestIdentifiers = .init()
        self.pendingSubscriptionRequestIdentifiers = .init()
        self.subscriptionCancellationRegistrations = .init()
        self.subscriptionCleanupTasks = .init()
        self.subscriptionSetupRequestIdentifiers = .init()
        self.subscriptionSetupTasks = .init()
        self.logger = logger ?? SwiftFulcrum.Logging.ConsoleAdapter()
        self.protocolNegotiation = protocolNegotiation
        self.state = .init()
        self.rpcHeartbeatInterval = heartbeatInterval
        self.rpcHeartbeatTimeout = heartbeatTimeout
        if let metrics { Task { await self.transport.updateMetrics(metrics) } }
        Task { await self.transport.updateLogger(self.logger) }
    }
    
    func start() async throws {
        if let startupTask {
            return try await startupTask.value
        }

        let owner = self
        let startupTask = Task<Void, Swift.Error> {
            try await owner.performStart()
        }
        self.startupTask = startupTask
        defer {
            self.startupTask = nil
        }

        try await startupTask.value
    }

    private func performStart() async throws {
        guard receiveTask == nil else { return }
        resetNegotiatedSession()
        
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
        if let startupTask {
            startupTask.cancel()
            _ = try? await startupTask.value
            self.startupTask = nil
        }

        if let reconnectTask {
            resetNegotiatedSession()
            reconnectTask.cancel()
            _ = try? await reconnectTask.value
            self.reconnectTask = nil
        }

        let info = await transport.closeInformation
        let closedError = await SwiftFulcrum.Client.Error.transport(.connectionClosed(info.code, info.reason))
        let inflightCount = await router.failAll(with: closedError)
        await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
        
        await stopRPCHeartbeat()
        await cancelBackgroundTasks()
        await transport.disconnect(with: "FulcrumNetworkClient.stop() called")
        resetNegotiatedSession()
    }
    
    func reconnect(with url: URL? = nil) async throws {
        if let reconnectTask {
            return try await reconnectTask.value
        }

        let owner = self
        let reconnectTask = Task<Void, Swift.Error> {
            await owner.cancelBackgroundTasks()
            await owner.resetNegotiatedSession()
            try await owner.transport.reconnect(with: url)
            await owner.startReceivingTask()

            do {
                _ = try await owner.ensureNegotiatedProtocol()
                await owner.emitLog(.info, "client.reconnect_resubscribe.begin")
                await owner.resubscribeStoredMethods()
                await owner.emitLog(.info,
                                   "client.reconnect_resubscribe.end",
                                   metadata: ["count": String(owner.subscriptionMethods.count)])
                await owner.startLifecycleObservationTasks()
                await owner.publishDiagnosticsSnapshot()
            } catch {
                await owner.cancelBackgroundTasks()
                await owner.transport.disconnect(with: "FulcrumNetworkClient.reconnect() negotiation failed")
                throw error
            }
        }

        self.reconnectTask = reconnectTask
        defer {
            self.reconnectTask = nil
        }

        try await reconnectTask.value
    }
    
    func makeConnectionStateEvents() async -> AsyncStream<SwiftFulcrum.Client.ConnectionState> {
        await transport.makeConnectionStateEvents()
    }

    func awaitReconnectReadiness() async throws {
        guard let reconnectTask else { return }
        try await reconnectTask.value
    }
    
    private func startReceivingTask() {
        receiveTask = Task { await self.startReceiving() }
    }
    
    private func startLifecycleObservationTasks() {
        lifecycleTask?.cancel()
        let owner = self
        lifecycleTask = Task {
            for await event in await owner.transport.makeLifecycleEvents() {
                await owner.publishDiagnosticsSnapshot()
                switch event {
                case .connected(let isReconnect) where isReconnect:
                    await owner.resetNegotiatedSession()
                    await owner.emitLog(.info, "client.autoresubscribe.begin")
                    do {
                        _ = try await owner.ensureNegotiatedProtocol()
                        await owner.resubscribeStoredMethods()
                        await owner.emitLog(.info,
                                           "client.autoresubscribe.end",
                                           metadata: ["count": String(owner.subscriptionMethods.count)])
                    } catch {
                        await owner.emitLog(.error,
                                           "client.protocol_negotiation.failed",
                                           metadata: ["error": error.localizedDescription])
                    }
                case .disconnected:
                    await owner.resetNegotiatedSession()
                default: break
                }
            }
        }
        
        diagnosticsStateTask?.cancel()
        diagnosticsStateTask = Task {
            let stream = await owner.transport.makeConnectionStateEvents()
            for await _ in stream {
                await owner.publishDiagnosticsSnapshot()
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
        _ level: SwiftFulcrum.Logging.Level,
        _ message: @autoclosure () -> String,
        metadata: [String: String] = .init(),
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) {
        var mergedMetadata = ["component": "FulcrumNetworkClient", "client_id": id.uuidString]
        mergedMetadata.merge(metadata, uniquingKeysWith: { _, new in new })
        logger.log(level, message(), metadata: mergedMetadata, file: file, function: function, line: line)
    }
}
