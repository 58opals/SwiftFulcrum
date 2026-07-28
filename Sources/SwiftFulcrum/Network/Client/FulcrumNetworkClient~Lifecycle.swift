// FulcrumNetworkClient~Lifecycle.swift

import Foundation

extension FulcrumNetworkClient {
    func startReceivingTask() {
        receiveTask = Task { await self.startReceiving() }
    }

    func startLifecycleObservationTasks() {
        lifecycleTask?.cancel()
        let owner = self
        lifecycleTask = Task {
            for await event in await owner.transport.makeLifecycleEvents() {
                await owner.recordClientState()
                switch event {
                case .connected(let isReconnect) where isReconnect:
                    await owner.handleSuccessfulTransportReconnect()
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
                await owner.recordClientState()
            }
        }
    }

    func cancelAndNil(_ task: Task<Void, Never>?) async -> Task<Void, Never>? {
        guard let task else { return nil }
        task.cancel()
        await task.value
        return nil
    }

    func cancelBackgroundTasks() async {
        receiveTask = await cancelAndNil(receiveTask)
        lifecycleTask = await cancelAndNil(lifecycleTask)
        diagnosticsStateTask = await cancelAndNil(diagnosticsStateTask)
        await cancelAutomaticReconnectRecoveryTask()
    }

    func handleSuccessfulTransportReconnect() async {
        let reconnectSuccessCount = await transport.reconnectSuccesses
        guard reconnectSuccessCount > recoveredReconnectSuccessCount else {
            return
        }

        if reconnectTask != nil,
           manualReconnectRecoverySuccessCount == reconnectSuccessCount {
            return
        }
        if reconnectRecoveryState.recoveryTask != nil,
           automaticReconnectRecoverySuccessCount == reconnectSuccessCount {
            return
        }

        if reconnectTask != nil {
            notePendingManualReconnectRecovery(
                reconnectSuccessCount: reconnectSuccessCount
            )
            await failInflightUnaryCallsForReconnect()
            return
        }
        _ = await beginAutomaticReconnectRecovery(
            reconnectSuccessCount: reconnectSuccessCount
        )
    }

    func notePendingManualReconnectRecovery(reconnectSuccessCount: Int) {
        pendingManualReconnectRecoverySuccessCount = max(
            reconnectSuccessCount,
            pendingManualReconnectRecoverySuccessCount ?? 0
        )
    }

    @discardableResult
    func advanceConnectionRecoveryGeneration() -> UInt64 {
        connectionRecoveryGeneration &+= 1
        return connectionRecoveryGeneration
    }

    func failInflightUnaryCallsForReconnect() async {
        let error = makeReconnectSupersededRouteError()
        let inflightCount = await router.failUnaries(with: error)
        await recordClientState(inflightUnaryCallCount: inflightCount)
    }

    func makeReconnectSupersededRouteError() -> SwiftFulcrum.Client.Error {
        .transport(
            .connectionClosed(
                .goingAway,
                "Connection superseded by reconnect."
            )
        )
    }

    func isReconnectSupersededRouteError(_ error: Swift.Error) -> Bool {
        guard let clientError = error as? SwiftFulcrum.Client.Error else {
            return false
        }
        return clientError == makeReconnectSupersededRouteError()
    }
}
