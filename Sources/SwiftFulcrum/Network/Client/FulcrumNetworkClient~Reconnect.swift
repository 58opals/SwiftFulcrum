// FulcrumNetworkClient~Reconnect.swift

import Foundation

extension FulcrumNetworkClient {
    func awaitReconnectReadiness() async throws {
        while true {
            if let reconnectTask {
                try await reconnectTask.awaitCancellableValue(
                    cancelUnderlyingTask: false
                )
                continue
            }

            if let recoveryTask = reconnectRecoveryState.recoveryTask {
                try await awaitAutomaticReconnectRecoveryTask(recoveryTask)
                continue
            }

            let connectionState = await transport.connectionState
            if reconnectTask != nil
                || reconnectRecoveryState.recoveryTask != nil {
                continue
            }

            switch connectionState {
            case .connected:
                let reconnectSuccessCountBeforeStateRead =
                    await transport.reconnectSuccesses
                let confirmedConnectionState = await transport.connectionState
                let reconnectSuccessCount = await transport.reconnectSuccesses
                if reconnectTask != nil
                    || reconnectRecoveryState.recoveryTask != nil {
                    continue
                }
                guard confirmedConnectionState == .connected,
                      reconnectSuccessCount
                        == reconnectSuccessCountBeforeStateRead else {
                    continue
                }

                if reconnectSuccessCount > recoveredReconnectSuccessCount {
                    if let recoveryTask = await beginAutomaticReconnectRecovery(
                        reconnectSuccessCount: reconnectSuccessCount
                    ) {
                        try await awaitAutomaticReconnectRecoveryTask(recoveryTask)
                    }
                    continue
                }

                guard reconnectRecoveryState.needsRecovery else { return }
                try await awaitAutomaticReconnectRecovery()
            case .reconnecting:
                prepareForAutomaticReconnectRecovery()
                try await waitForAutomaticReconnectConnection()
            case .connecting:
                try await waitForAutomaticReconnectConnection()
            case .disconnected, .idle:
                try await awaitAutomaticReconnectRecovery()
            }
        }
    }

    func awaitAutomaticReconnectRecovery() async throws {
        let state = await transport.connectionState
        switch state {
        case .connected:
            if let recoveryTask = await beginAutomaticReconnectRecovery() {
                try await awaitAutomaticReconnectRecoveryTask(recoveryTask)
            }
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
                if let recoveryTask = await beginAutomaticReconnectRecovery() {
                    try await awaitAutomaticReconnectRecoveryTask(recoveryTask)
                }
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
            try await recoveryTask.awaitCancellableValue(
                cancelUnderlyingTask: false
            )
        } catch is CancellationError {
            if Task.isCancelled {
                throw CancellationError()
            }
            guard reconnectRecoveryState.needsRecovery else { throw CancellationError() }
            try await awaitAutomaticReconnectRecovery()
        }
    }
}
