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

    var subscriptionRegistry: SubscriptionRegistry

    var receiveTask: Task<Void, Never>?
    var startupTask: Task<Void, Swift.Error>?
    var startupTaskGenerationIdentifier: UUID?
    var startupTaskWaiterCountsByGeneration = [UUID: Int]()
    var reconnectTask: Task<Void, Swift.Error>?
    var reconnectTaskGenerationIdentifier: UUID?
    var reconnectTaskWaiterCountsByGeneration = [UUID: Int]()
    var reconnectRecoveryState: ReconnectRecoveryState
    var reconnectRecoveryTaskGenerationIdentifier: UUID?
    var automaticReconnectRecoveryPredecessorTask: Task<Void, Swift.Error>?
    var automaticReconnectRecoverySuccessCount: Int?
    var automaticReconnectRecoveryGeneration: UInt64?
    var manualReconnectRecoverySuccessCount: Int?
    var pendingManualReconnectRecoverySuccessCount: Int?
    var automaticReconnectConnectionGeneration: UInt64 = 0
    var connectionRecoveryGeneration: UInt64 = 0
    var recoveredReconnectSuccessCount = 0
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
        self.subscriptionRegistry = .init()
        self.protocolNegotiation = protocolNegotiation
        self.state = .init()
        self.reconnectRecoveryState = .idle
        self.rpcHeartbeatInterval = heartbeatInterval
        self.rpcHeartbeatTimeout = heartbeatTimeout
    }

    func stop() async {
        let startupTask = self.startupTask
        let startupTaskGenerationIdentifier = self.startupTaskGenerationIdentifier

        startupTask?.cancel()
        await stopRPCHeartbeat()

        let reconnectTask = self.reconnectTask
        let reconnectTaskGenerationIdentifier = self.reconnectTaskGenerationIdentifier
        reconnectTask?.cancel()
        if reconnectTask != nil {
            resetNegotiatedSession()
        }

        await transport.disconnect(with: "FulcrumNetworkClient.stop() called")

        if let startupTask {
            _ = try? await startupTask.value
            if self.startupTaskGenerationIdentifier == startupTaskGenerationIdentifier {
                self.startupTask = nil
                self.startupTaskGenerationIdentifier = nil
            }
        }

        await stopRPCHeartbeat()

        if let reconnectTask {
            _ = try? await reconnectTask.value
            if self.reconnectTaskGenerationIdentifier == reconnectTaskGenerationIdentifier {
                self.reconnectTask = nil
                self.reconnectTaskGenerationIdentifier = nil
            }
        }

        let lateReconnectTask = self.reconnectTask
        let lateReconnectTaskGenerationIdentifier =
            self.reconnectTaskGenerationIdentifier
        if let lateReconnectTask {
            lateReconnectTask.cancel()
            resetNegotiatedSession()
            _ = try? await lateReconnectTask.value
            if self.reconnectTaskGenerationIdentifier
                == lateReconnectTaskGenerationIdentifier {
                self.reconnectTask = nil
                self.reconnectTaskGenerationIdentifier = nil
            }
        }

        await cancelBackgroundTasks()
        await transport.disconnect(with: "FulcrumNetworkClient.stop() called")

        let info = await transport.closeInformation
        let closedError = await SwiftFulcrum.Client.Error.transport(.connectionClosed(info.code, info.reason))
        await dropAllStoredSubscriptions()
        let inflightCount = await router.failAll(with: closedError)
        await recordClientState(inflightUnaryCallCount: inflightCount)

        resetNegotiatedSession()
    }

    func makeConnectionStateEvents() async -> AsyncStream<SwiftFulcrum.Client.ConnectionState> {
        await transport.makeConnectionStateEvents()
    }
}
