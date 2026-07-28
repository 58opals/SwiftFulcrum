// WebSocketConnection~Connection.swift

import Foundation
import OpalDiagnostics

extension WebSocketConnection {
    func connect(using attempt: ConnectionAttempt = .initial) async throws {
        try Task.checkCancellation()
        let generation = makeOrReuseConnectTask(using: attempt)
        try await waitForConnectTask(
            generation.task,
            generationIdentifier: generation.identifier
        )
    }

    func performConnect(using attempt: ConnectionAttempt = .initial) async throws {
        var connectionTask: URLSessionWebSocketTask?
        var didBeginConnecting = false
        do {
            try Task.checkCancellation()
            guard await !self.isConnected else { return }
            try Task.checkCancellation()
            await updateConnectionState(.connecting)
            didBeginConnecting = true
            try Task.checkCancellation()

            await createNewTask(with: nil, receiverCancellation: attempt.receiverCancellation)
            guard let task else {
                throw SwiftFulcrum.Client.Error.transport(
                    .connectionClosed(closeInformation.code, closeInformation.reason)
                )
            }
            connectionTask = task
            try Task.checkCancellation()

            task.resume()
            OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                event: .swiftFulcrumWebSocketConnectBegin,
                level: .info,
                fields: webSocketDiagnosticFields()
            )

            let connectionFailure: Swift.Error
            do {
                let isConnected = try await waitForConnection(timeout: connectionTimeout)
                try Task.checkCancellation()
                if isConnected {
                    if attempt.shouldRecordReconnectSuccess {
                        recordReconnectSuccess()
                    }
                    await updateConnectionState(.connected)
                    try Task.checkCancellation()
                    OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                        event: .swiftFulcrumWebSocketConnectSucceeded,
                        level: .info,
                        fields: webSocketDiagnosticFields()
                    )
                    if let connectedLifecycleEvent = attempt.connectedLifecycleEvent {
                        emitLifecycle(connectedLifecycleEvent)
                    }
                    ensureAutomaticReceiving()
                    return
                } else {
                    let timeoutReason = "Connection timed out."
                    let timeoutFailure = SwiftFulcrum.Client.Error.transport(
                        .connectionClosed(.goingAway, timeoutReason)
                    )
                    await updateConnectionState(attempt.failureState)
                    task.cancel(with: .goingAway, reason: timeoutReason.data(using: .utf8))
                    OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                        event: .swiftFulcrumWebSocketConnectTimeout,
                        level: .info,
                        fields: webSocketDiagnosticFields([
                            .errorCode(.clientTimeout),
                            .swiftFulcrumField(
                                "close_code",
                                URLSessionWebSocketTask.CloseCode.goingAway.rawValue
                            ),
                            .swiftFulcrumPrivateField("reason", timeoutReason)
                        ])
                    )
                    connectionFailure = timeoutFailure
                }
            } catch let networkError as SwiftFulcrum.Client.Error.Network {
                await updateConnectionState(attempt.failureState)
                task.cancel(
                    with: .goingAway,
                    reason: "Network error during connect.".data(using: .utf8)
                )
                connectionFailure = SwiftFulcrum.Client.Error.transport(.network(networkError))
            } catch {
                try Task.checkCancellation()
                await updateConnectionState(attempt.failureState)
                task.cancel(
                    with: .goingAway,
                    reason: "Connect failed.".data(using: .utf8)
                )
                connectionFailure = error
            }

            try Task.checkCancellation()
            try await performInitialFailoverIfNeeded(
                allowsFailover: attempt.allowsFailover,
                failure: connectionFailure
            )
        } catch is CancellationError {
            if let connectionTask {
                if await discardCancelledConnectionTask(connectionTask) {
                    await updateConnectionState(attempt.failureState)
                }
            } else if didBeginConnecting {
                await updateConnectionState(attempt.failureState)
            }
            throw CancellationError()
        }
    }

    private func performInitialFailoverIfNeeded(
        allowsFailover: Bool,
        failure: Error
    ) async throws {
        guard allowsFailover else { throw failure }

        OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
            event: .swiftFulcrumWebSocketConnectFailover,
            level: .info,
            fields: webSocketDiagnosticFields(OpalDiagnostics.Field.swiftFulcrumErrorFields(failure))
        )

        do {
            await updateConnectionState(.reconnecting)
            try await reconnector.attemptReconnection(
                for: self,
                attempt: .initialConnection
            )
        } catch is CancellationError {
            await updateConnectionState(.disconnected)
            throw CancellationError()
        } catch {
            OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                event: .swiftFulcrumWebSocketConnectFailoverExhausted,
                level: .info,
                fields: webSocketDiagnosticFields(OpalDiagnostics.Field.swiftFulcrumErrorFields(error))
            )

            throw error
        }
    }

    func reconnect(with url: URL? = nil) async throws {
        await disconnect(with: "WebSocketConnection.reconnect()")
        await updateConnectionState(.reconnecting)
        do {
            try await reconnector.attemptReconnection(for: self, with: url, attempt: .manualReconnect)
        } catch {
            await updateConnectionState(.disconnected)
            throw error
        }
    }
}
