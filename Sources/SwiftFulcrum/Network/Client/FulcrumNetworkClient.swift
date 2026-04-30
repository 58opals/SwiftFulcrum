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
    private var automaticReconnectRecoveryTask: Task<Void, Swift.Error>?
    private var needsAutomaticReconnectRecovery = false
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
        await cancelAutomaticReconnectRecoveryTask()

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

            do {
                try await owner.transport.reconnect(with: url)
                await owner.startReceivingTask()
                _ = try await owner.ensureNegotiatedProtocol()
                await owner.emitLog(.info, "client.reconnect_resubscribe.begin")
                await owner.resubscribeStoredMethods()
                await owner.emitLog(.info,
                                   "client.reconnect_resubscribe.end",
                                   metadata: ["count": String(owner.subscriptionMethods.count)])
                await owner.clearAutomaticReconnectRecoveryNeed()
                await owner.startLifecycleObservationTasks()
                await owner.publishDiagnosticsSnapshot()
            } catch {
                await owner.cancelBackgroundTasks()
                await owner.transport.disconnect(with: "FulcrumNetworkClient.reconnect() failed")
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
        if let reconnectTask {
            try await reconnectTask.value
            return
        }

        if await transport.connectionState == .reconnecting {
            prepareForAutomaticReconnectRecovery()
            try await waitForAutomaticReconnectConnection()
            return
        }

        if let automaticReconnectRecoveryTask {
            try await automaticReconnectRecoveryTask.value
            return
        }

        guard needsAutomaticReconnectRecovery else { return }
        try await awaitAutomaticReconnectRecovery()
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
                    await owner.markAutomaticReconnectRecoveryNeeded()
                    let recoveryTask = await owner.makeOrReuseAutomaticReconnectRecoveryTask()
                    do {
                        try await recoveryTask.value
                    } catch {
                        await owner.emitLog(.error,
                                           "client.protocol_negotiation.failed",
                                           metadata: ["error": error.localizedDescription])
                        await owner.handleAutomaticReconnectRecoveryFailure(error)
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
            for await state in stream {
                if state == .reconnecting {
                    await owner.prepareForAutomaticReconnectRecoveryIfNeeded()
                }
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
        await cancelAutomaticReconnectRecoveryTask()
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

private extension FulcrumNetworkClient {
    func awaitAutomaticReconnectRecovery() async throws {
        var didPrepareForReconnect = false

        while true {
            let state = await transport.connectionState
            switch state {
            case .connected:
                let recoveryTask = makeOrReuseAutomaticReconnectRecoveryTask()
                try await recoveryTask.value
                return
            case .reconnecting:
                if !didPrepareForReconnect {
                    prepareForAutomaticReconnectRecovery()
                    didPrepareForReconnect = true
                }
                try await waitForAutomaticReconnectConnection()
                return
            case .connecting:
                try await waitForAutomaticReconnectConnection()
                return
            case .disconnected:
                let info = await transport.closeInformation
                throw SwiftFulcrum.Client.Error.transport(.connectionClosed(info.code, info.reason))
            case .idle:
                throw CancellationError()
            }
        }
    }

    func waitForAutomaticReconnectConnection() async throws {
        while true {
            let state = await transport.connectionState
            switch state {
            case .connected:
                let recoveryTask = makeOrReuseAutomaticReconnectRecoveryTask()
                try await recoveryTask.value
                return
            case .disconnected:
                let info = await transport.closeInformation
                throw SwiftFulcrum.Client.Error.transport(.connectionClosed(info.code, info.reason))
            case .idle:
                throw CancellationError()
            case .connecting, .reconnecting:
                try await Task.sleep(for: .milliseconds(10))
            }
        }
    }

    func prepareForAutomaticReconnectRecovery() {
        automaticReconnectRecoveryTask?.cancel()
        automaticReconnectRecoveryTask = nil
        needsAutomaticReconnectRecovery = true
    }

    func prepareForAutomaticReconnectRecoveryIfNeeded() {
        guard reconnectTask == nil else { return }
        prepareForAutomaticReconnectRecovery()
    }

    func markAutomaticReconnectRecoveryNeeded() {
        guard reconnectTask == nil else { return }
        if automaticReconnectRecoveryTask == nil {
            needsAutomaticReconnectRecovery = true
        }
    }

    func makeOrReuseAutomaticReconnectRecoveryTask() -> Task<Void, Swift.Error> {
        if let automaticReconnectRecoveryTask {
            return automaticReconnectRecoveryTask
        }

        let owner = self
        let task = Task<Void, Swift.Error> {
            try await owner.performAutomaticReconnectRecovery()
        }
        automaticReconnectRecoveryTask = task
        return task
    }

    func performAutomaticReconnectRecovery() async throws {
        resetNegotiatedSession()
        emitLog(.info, "client.autoresubscribe.begin")

        _ = try await ensureNegotiatedProtocol()
        await resubscribeStoredMethods()
        needsAutomaticReconnectRecovery = false
        emitLog(.info,
                "client.autoresubscribe.end",
                metadata: ["count": String(subscriptionMethods.count)])
    }

    func handleAutomaticReconnectRecoveryFailure(_ error: Swift.Error) async {
        automaticReconnectRecoveryTask = nil
        needsAutomaticReconnectRecovery = false
        resetNegotiatedSession()

        let inflightCount = await router.failAll(with: error)
        await dropAllStoredSubscriptions()
        await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
        await transport.disconnect(with: "FulcrumNetworkClient automatic reconnect recovery failed")
    }

    func clearAutomaticReconnectRecoveryNeed() {
        needsAutomaticReconnectRecovery = false
    }

    func cancelAutomaticReconnectRecoveryTask() async {
        guard let automaticReconnectRecoveryTask else {
            needsAutomaticReconnectRecovery = false
            return
        }
        automaticReconnectRecoveryTask.cancel()
        _ = try? await automaticReconnectRecoveryTask.value
        self.automaticReconnectRecoveryTask = nil
        needsAutomaticReconnectRecovery = false
    }
}
