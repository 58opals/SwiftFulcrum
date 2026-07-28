// Client~RequestPreparation.swift

import Foundation

extension SwiftFulcrum.Client {
    func throwIfCancelled(_ token: FulcrumNetworkClient.Call.Token?) async throws {
        guard let token, await token.isCancelled else { return }
        throw SwiftFulcrum.Client.Error.client(.cancelled)
    }

    func prepareClientForRequests(
        until deadline: TimeoutDeadline?,
        observedStopGeneration: UInt64
    ) async throws {
        if !isRunning {
            try await executeBeforeDeadline(deadline) {
                try await self.startClientIfRequestPreparationIsCurrent(
                    observedStopGeneration: observedStopGeneration
                )
            }
            try ensureRequestPreparationIsCurrent(
                observedStopGeneration: observedStopGeneration
            )
        }

        let state = await client.connectionState
        try ensureRequestPreparationIsCurrent(
            observedStopGeneration: observedStopGeneration
        )
        updateConnectionState(state)

        switch state {
        case .connected:
            break
        case .connecting:
            try await executeBeforeDeadline(deadline) {
                try await self.waitForClientConnectionToBecomeReady(
                    observedStopGeneration: observedStopGeneration
                )
            }
        case .reconnecting:
            break
        case .idle:
            try await executeBeforeDeadline(deadline) {
                try await self.startNetworkClientIfRequestPreparationIsCurrent(
                    observedStopGeneration: observedStopGeneration
                )
            }
        case .disconnected:
            try await executeBeforeDeadline(deadline) {
                try await self.reconnectClientIfRequestPreparationIsCurrent(
                    observedStopGeneration: observedStopGeneration
                )
            }
        }

        try await executeBeforeDeadline(deadline) {
            try await self.awaitReconnectReadinessIfRequestPreparationIsCurrent(
                observedStopGeneration: observedStopGeneration
            )
        }
        try ensureRequestPreparationIsCurrent(
            observedStopGeneration: observedStopGeneration
        )
    }

    func waitForClientConnectionToBecomeReady(
        observedStopGeneration: UInt64
    ) async throws {
        for await state in makeConnectionStateStream() {
            try ensureRequestPreparationIsCurrent(
                observedStopGeneration: observedStopGeneration
            )
            switch state {
            case .connected:
                return
            case .idle:
                try await client.start()
                try ensureRequestPreparationIsCurrent(
                    observedStopGeneration: observedStopGeneration
                )
                return
            case .disconnected:
                try await client.reconnect()
                try ensureRequestPreparationIsCurrent(
                    observedStopGeneration: observedStopGeneration
                )
                return
            case .connecting, .reconnecting:
                continue
            }
        }

        throw CancellationError()
    }

    func startClientIfRequestPreparationIsCurrent(
        observedStopGeneration: UInt64
    ) async throws {
        try ensureStopGenerationIsCurrent(
            observedStopGeneration: observedStopGeneration
        )
        try await start()
        try ensureRequestPreparationIsCurrent(
            observedStopGeneration: observedStopGeneration
        )
    }

    func startNetworkClientIfRequestPreparationIsCurrent(
        observedStopGeneration: UInt64
    ) async throws {
        try ensureRequestPreparationIsCurrent(
            observedStopGeneration: observedStopGeneration
        )
        try await client.start()
        try ensureRequestPreparationIsCurrent(
            observedStopGeneration: observedStopGeneration
        )
    }

    func reconnectClientIfRequestPreparationIsCurrent(
        observedStopGeneration: UInt64
    ) async throws {
        try ensureRequestPreparationIsCurrent(
            observedStopGeneration: observedStopGeneration
        )
        try await client.reconnect()
        try ensureRequestPreparationIsCurrent(
            observedStopGeneration: observedStopGeneration
        )
    }

    func awaitReconnectReadinessIfRequestPreparationIsCurrent(
        observedStopGeneration: UInt64
    ) async throws {
        try ensureRequestPreparationIsCurrent(
            observedStopGeneration: observedStopGeneration
        )
        try await client.awaitReconnectReadiness()
        try ensureRequestPreparationIsCurrent(
            observedStopGeneration: observedStopGeneration
        )
    }

    func ensureStopGenerationIsCurrent(
        observedStopGeneration: UInt64
    ) throws {
        guard stopGeneration == observedStopGeneration else {
            throw SwiftFulcrum.Client.Error.client(.cancelled)
        }
    }

    func ensureRequestPreparationIsCurrent(
        observedStopGeneration: UInt64
    ) throws {
        guard desiredRunning,
              stopGeneration == observedStopGeneration else {
            throw SwiftFulcrum.Client.Error.client(.cancelled)
        }
    }
}
