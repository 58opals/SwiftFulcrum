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
                        .swiftFulcrumField("subscription_count", owner.subscriptionMethods.count)
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
        OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
            event: .swiftFulcrumClientReconnectRecoveryBegin,
            level: .info,
            fields: await makeClientTransportDiagnosticFields()
        )

        _ = try await ensureNegotiatedProtocol()
        await resubscribeStoredMethods()
        needsAutomaticReconnectRecovery = false
        OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
            event: .swiftFulcrumClientReconnectRecoverySucceeded,
            level: .info,
            fields: await makeClientTransportDiagnosticFields([
                .swiftFulcrumField("subscription_count", subscriptionMethods.count)
            ])
        )
    }

    func handleAutomaticReconnectRecoveryFailure(_ error: Swift.Error) async {
        automaticReconnectRecoveryTask = nil
        needsAutomaticReconnectRecovery = false
        resetNegotiatedSession()

        let inflightCount = await router.failAll(with: error)
        await dropAllStoredSubscriptions()
        await recordClientState(inflightUnaryCallCount: inflightCount)
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
