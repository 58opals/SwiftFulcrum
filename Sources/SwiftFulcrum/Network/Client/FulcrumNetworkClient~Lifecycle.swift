// FulcrumNetworkClient~Lifecycle.swift

import Foundation
import OpalDiagnostics

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
                    await owner.markAutomaticReconnectRecoveryNeeded()
                    let recoveryTask = await owner.makeOrReuseAutomaticReconnectRecoveryTask()
                    _ = try? await recoveryTask.value
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
}
