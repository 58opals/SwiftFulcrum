// FulcrumNetworkClient~Reconnect.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
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
                OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
                    event: .swiftFulcrumClientReconnectRecoveryBegin,
                    level: .info,
                    fields: await owner.makeClientTransportDiagnosticFields()
                )
                await owner.resubscribeStoredMethods()
                OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
                    event: .swiftFulcrumClientReconnectRecoverySucceeded,
                    level: .info,
                    fields: await owner.makeClientTransportDiagnosticFields([
                        .swiftFulcrumField("subscription_count", owner.subscriptionRegistry.count)
                    ])
                )
                await owner.clearAutomaticReconnectRecoveryNeed()
                await owner.startLifecycleObservationTasks()
                await owner.recordClientState()
            } catch {
                await owner.cancelBackgroundTasks()
                OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
                    event: .swiftFulcrumClientReconnectRecoveryFailed,
                    level: .info,
                    fields: await owner.makeClientTransportDiagnosticFields(OpalDiagnostics.Field.swiftFulcrumErrorFields(error))
                )
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

    func awaitReconnectReadiness() async throws {
        if let reconnectTask {
            try await reconnectTask.value
            return
        }

        if let recoveryTask = reconnectRecoveryState.recoveryTask {
            try await awaitAutomaticReconnectRecoveryTask(recoveryTask)
            return
        }

        if await transport.connectionState == .reconnecting {
            prepareForAutomaticReconnectRecovery()
            try await waitForAutomaticReconnectConnection()
            return
        }

        guard reconnectRecoveryState.needsRecovery else { return }
        try await awaitAutomaticReconnectRecovery()
    }

    func awaitAutomaticReconnectRecovery() async throws {
        let state = await transport.connectionState
            switch state {
            case .connected:
                let recoveryTask = makeOrReuseAutomaticReconnectRecoveryTask()
                try await awaitAutomaticReconnectRecoveryTask(recoveryTask)
            case .reconnecting:
                prepareForAutomaticReconnectRecovery()
                try await waitForAutomaticReconnectConnection()
        case .connecting:
            try await waitForAutomaticReconnectConnection()
        case .disconnected:
            reconnectRecoveryState = .idle
            let info = await transport.closeInformation
            throw SwiftFulcrum.Client.Error.transport(.connectionClosed(info.code, info.reason))
        case .idle:
            reconnectRecoveryState = .idle
            throw CancellationError()
        }
    }

    func waitForAutomaticReconnectConnection() async throws {
        reconnectRecoveryState = .waitingForConnection
        let stream = await transport.makeConnectionStateEvents()
        for await state in stream {
            switch state {
            case .connected:
                let recoveryTask = makeOrReuseAutomaticReconnectRecoveryTask()
                try await awaitAutomaticReconnectRecoveryTask(recoveryTask)
                return
            case .disconnected:
                reconnectRecoveryState = .idle
                let info = await transport.closeInformation
                throw SwiftFulcrum.Client.Error.transport(.connectionClosed(info.code, info.reason))
            case .idle:
                reconnectRecoveryState = .idle
                throw CancellationError()
            case .connecting, .reconnecting:
                continue
            }
        }

        reconnectRecoveryState = .idle
        throw CancellationError()
    }

    func awaitAutomaticReconnectRecoveryTask(_ recoveryTask: Task<Void, Swift.Error>) async throws {
        do {
            try await recoveryTask.value
        } catch is CancellationError {
            guard reconnectRecoveryState.needsRecovery else { throw CancellationError() }
            try await awaitAutomaticReconnectRecovery()
        }
    }

    func prepareForAutomaticReconnectRecovery() {
        reconnectRecoveryState.recoveryTask?.cancel()
        reconnectRecoveryState = .needed
    }

    func prepareForAutomaticReconnectRecoveryIfNeeded() {
        guard reconnectTask == nil else { return }
        prepareForAutomaticReconnectRecovery()
    }

    func markAutomaticReconnectRecoveryNeeded() {
        guard reconnectTask == nil else { return }
        if reconnectRecoveryState.recoveryTask == nil {
            reconnectRecoveryState = .needed
        }
    }

    func makeOrReuseAutomaticReconnectRecoveryTask() -> Task<Void, Swift.Error> {
        if let recoveryTask = reconnectRecoveryState.recoveryTask {
            return recoveryTask
        }

        let owner = self
        let task = Task<Void, Swift.Error> {
            do {
                try await owner.performAutomaticReconnectRecovery()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
                    event: .swiftFulcrumClientReconnectRecoveryFailed,
                    level: .info,
                    fields: await owner.makeClientTransportDiagnosticFields(OpalDiagnostics.Field.swiftFulcrumErrorFields(error))
                )
                await owner.handleAutomaticReconnectRecoveryFailure(error)
                throw error
            }
        }
        reconnectRecoveryState = .recovering(task)
        return task
    }

    func performAutomaticReconnectRecovery() async throws {
        resetNegotiatedSession()
        OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
            event: .swiftFulcrumClientReconnectRecoveryBegin,
            level: .info,
            fields: await makeClientTransportDiagnosticFields()
        )

        _ = try await ensureNegotiatedProtocol()
        await resubscribeStoredMethods()
        reconnectRecoveryState = .idle
        OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
            event: .swiftFulcrumClientReconnectRecoverySucceeded,
            level: .info,
            fields: await makeClientTransportDiagnosticFields([
                .swiftFulcrumField("subscription_count", subscriptionRegistry.count)
            ])
        )
    }

    func handleAutomaticReconnectRecoveryFailure(_ error: Swift.Error) async {
        reconnectRecoveryState = .idle
        resetNegotiatedSession()

        let inflightCount = await router.failAll(with: error)
        await dropAllStoredSubscriptions()
        await recordClientState(inflightUnaryCallCount: inflightCount)
        await transport.disconnect(with: "FulcrumNetworkClient automatic reconnect recovery failed")
    }

    func clearAutomaticReconnectRecoveryNeed() {
        reconnectRecoveryState = .idle
    }

    func cancelAutomaticReconnectRecoveryTask() async {
        guard let recoveryTask = reconnectRecoveryState.recoveryTask else {
            reconnectRecoveryState = .idle
            return
        }
        recoveryTask.cancel()
        _ = try? await recoveryTask.value
        reconnectRecoveryState = .idle
    }
}
