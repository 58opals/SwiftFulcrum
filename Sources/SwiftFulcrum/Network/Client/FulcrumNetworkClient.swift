// FulcrumNetworkClient.swift

import Foundation
import OpalDiagnostics

actor FulcrumNetworkClient {
    let id: UUID
    let transport: TransportAdapter
    var jsonRPC: JSONRPCCodec
    let router: Router
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
    private var startupWaiterCount = 0
    var reconnectTask: Task<Void, Swift.Error>?
    var automaticReconnectRecoveryTask: Task<Void, Swift.Error>?
    var needsAutomaticReconnectRecovery = false
    var lifecycleTask: Task<Void, Never>?
    var diagnosticsStateTask: Task<Void, Never>?

    var rpcHeartbeatTask: Task<Void, Never>?
    let rpcHeartbeatInterval: Duration
    let rpcHeartbeatTimeout: Duration

    var connectionState: SwiftFulcrum.Client.ConnectionState { get async { await transport.connectionState } }

    init(transport: TransportAdapter,
         heartbeatInterval: Duration = .seconds(25),
         heartbeatTimeout: Duration = .seconds(10),
         protocolNegotiation: SwiftFulcrum.Client.Configuration.ProtocolNegotiation) {
        self.id = .init()
        self.transport = transport
        self.jsonRPC = .init()
        self.router = .init()
        self.subscriptionMethods = .init()
        self.activeSubscriptionRequestIdentifiers = .init()
        self.pendingSubscriptionRequestIdentifiers = .init()
        self.subscriptionCancellationRegistrations = .init()
        self.subscriptionCleanupTasks = .init()
        self.subscriptionSetupRequestIdentifiers = .init()
        self.subscriptionSetupTasks = .init()
        self.protocolNegotiation = protocolNegotiation
        self.state = .init()
        self.rpcHeartbeatInterval = heartbeatInterval
        self.rpcHeartbeatTimeout = heartbeatTimeout
    }

    func start() async throws {
        let startupTask: Task<Void, Swift.Error>
        if let existingStartupTask = self.startupTask {
            startupTask = existingStartupTask
        } else {
            let owner = self
            startupTask = Task<Void, Swift.Error> {
                try await owner.performStart()
            }
            self.startupTask = startupTask
        }

        startupWaiterCount += 1
        defer {
            startupWaiterCount -= 1
            if Task.isCancelled, startupWaiterCount == 0 {
                startupTask.cancel()
                self.startupTask = nil
            }
        }

        do {
            try await startupTask.awaitCancellableValue(cancelUnderlyingTask: false)
            self.startupTask = nil
        } catch {
            if Task.isCancelled, error is CancellationError {
                throw error
            }
            self.startupTask = nil
            throw error
        }
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
            await recordClientState()
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
        await dropAllStoredSubscriptions()
        let inflightCount = await router.failAll(with: closedError)
        await recordClientState(inflightUnaryCallCount: inflightCount)

        await stopRPCHeartbeat()
        await cancelBackgroundTasks()
        await transport.disconnect(with: "FulcrumNetworkClient.stop() called")
        resetNegotiatedSession()
    }

    func makeConnectionStateEvents() async -> AsyncStream<SwiftFulcrum.Client.ConnectionState> {
        await transport.makeConnectionStateEvents()
    }
}
