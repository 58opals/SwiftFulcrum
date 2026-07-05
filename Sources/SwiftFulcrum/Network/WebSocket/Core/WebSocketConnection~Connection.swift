// WebSocketConnection~Connection.swift

import Foundation
import OpalDiagnostics

extension WebSocketConnection {
    func connect(using attempt: ConnectionAttempt = .initial) async throws {
        if self.connectTask != nil {
            return try await waitForActiveConnectTask()
        }

        let connection = self
        let connectTask = Task<Void, Swift.Error> {
            try await connection.performConnect(using: attempt)
        }
        self.connectTask = connectTask
        defer {
            self.connectTask = nil
        }

        do {
            try await connectTask.value
            finishConnectTaskWaiters(.success(()))
        } catch {
            finishConnectTaskWaiters(.failure(error))
            throw error
        }
    }

    func performConnect(using attempt: ConnectionAttempt = .initial) async throws {
        guard await !self.isConnected else { return }
        await updateConnectionState(.connecting)

        await createNewTask(with: nil, receiverCancellation: attempt.receiverCancellation)
        guard let task else {
            throw SwiftFulcrum.Client.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
        }

        task.resume()
        OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
            event: .swiftFulcrumWebSocketConnectBegin,
            level: .info,
            fields: webSocketDiagnosticFields()
        )

        do {
            let isConnected = try await waitForConnection(timeout: connectionTimeout)
            if isConnected {
                await updateConnectionState(.connected)
                OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                    event: .swiftFulcrumWebSocketConnectSucceeded,
                    level: .info,
                    fields: webSocketDiagnosticFields()
                )
                if let connectedLifecycleEvent = attempt.connectedLifecycleEvent {
                    emitLifecycle(connectedLifecycleEvent)
                }
                ensureAutomaticReceiving()
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
                        .swiftFulcrumField("close_code", URLSessionWebSocketTask.CloseCode.goingAway.rawValue),
                        .swiftFulcrumPrivateField("reason", timeoutReason)
                    ])
                )
                try await performInitialFailoverIfNeeded(
                    allowsFailover: attempt.allowsFailover,
                    failure: timeoutFailure
                )
            }
        } catch let networkError as SwiftFulcrum.Client.Error.Network {
            await updateConnectionState(attempt.failureState)
            task.cancel(with: .goingAway, reason: "Network error during connect.".data(using: .utf8))
            try await performInitialFailoverIfNeeded(
                allowsFailover: attempt.allowsFailover,
                failure: SwiftFulcrum.Client.Error.transport(.network(networkError))
            )
        } catch {
            await updateConnectionState(attempt.failureState)
            task.cancel(with: .goingAway, reason: "Connect failed.".data(using: .utf8))
            try await performInitialFailoverIfNeeded(
                allowsFailover: attempt.allowsFailover,
                failure: error
            )
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

    func disconnect(with reason: String? = nil) async {
        await cancelReceiverTask()

        let existingInformation = closeInformation
        if let task {
            await connectionEventTracker.stopTracking(taskIdentifier: task.taskIdentifier)
        }

        task?.cancel(with: .goingAway, reason: reason?.data(using: .utf8))
        task = nil

        let finalInformation: (code: URLSessionWebSocketTask.CloseCode, reason: String?)
        if let reason {
            finalInformation = (.goingAway, reason)
        } else {
            finalInformation = existingInformation
        }
        lastCloseInformation = finalInformation

        await updateConnectionState(.disconnected)

        let closedError = SwiftFulcrum.Client.Error.transport(
            .connectionClosed(finalInformation.code, finalInformation.reason)
        )

        finishConnectWaiters(.failure(closedError))

        messageContinuation?.finish(throwing: closedError)

        await resetMessageStreamAndReader()
        OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
            event: .swiftFulcrumWebSocketDisconnect,
            level: .info,
            fields: webSocketDiagnosticFields([
                .swiftFulcrumField("close_code", finalInformation.code.rawValue),
                .swiftFulcrumPrivateField("reason", finalInformation.reason ?? "")
            ])
        )
        emitLifecycle(.disconnected(code: finalInformation.code, reason: finalInformation.reason))
    }
}
