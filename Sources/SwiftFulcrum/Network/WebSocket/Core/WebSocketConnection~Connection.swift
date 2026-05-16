// WebSocketConnection~Connection.swift

import Foundation

extension WebSocketConnection {
    func connect(
        shouldEmitLifecycle: Bool = true,
        shouldAllowFailover: Bool = true,
        shouldCancelReceiver: Bool = true
    ) async throws {
        if self.connectTask != nil {
            return try await waitForActiveConnectTask()
        }

        let connection = self
        let connectTask = Task<Void, Swift.Error> {
            try await connection.performConnect(
                shouldEmitLifecycle: shouldEmitLifecycle,
                shouldAllowFailover: shouldAllowFailover,
                shouldCancelReceiver: shouldCancelReceiver
            )
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

    func performConnect(
        shouldEmitLifecycle: Bool = true,
        shouldAllowFailover: Bool = true,
        shouldCancelReceiver: Bool = true,
        failureState: ConnectionState = .disconnected
    ) async throws {
        guard await !self.isConnected else { return }
        await updateConnectionState(.connecting)
        
        await createNewTask(with: nil, shouldCancelReceiver: shouldCancelReceiver)
        guard let task else {
            throw SwiftFulcrum.Client.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
        }
        
        task.resume()
        recordWebSocketEvent(SwiftFulcrumDiagnostics.Event.webSocketConnectBegin, level: .info)
        
        do {
            let isConnected = try await waitForConnection(timeout: connectionTimeout)
            if isConnected {
                await updateConnectionState(.connected)
                recordWebSocketEvent(SwiftFulcrumDiagnostics.Event.webSocketConnectSucceeded, level: .info)
                if shouldEmitLifecycle { emitLifecycle(.connected(isReconnect: false)) }
                ensureAutomaticReceiving()
            } else {
                let timeoutReason = "Connection timed out."
                let timeoutFailure = SwiftFulcrum.Client.Error.transport(
                    .connectionClosed(.goingAway, timeoutReason)
                )
                await updateConnectionState(failureState)
                task.cancel(with: .goingAway, reason: timeoutReason.data(using: .utf8))
                recordWebSocketEvent(
                    SwiftFulcrumDiagnostics.Event.webSocketConnectTimeout,
                    level: .error,
                    fields: [
                        SwiftFulcrumDiagnostics.errorCodeField(SwiftFulcrum.Client.Diagnostics.ErrorCode.clientTimeout),
                        SwiftFulcrumDiagnostics.publicField("close_code", URLSessionWebSocketTask.CloseCode.goingAway.rawValue),
                        SwiftFulcrumDiagnostics.privateField("reason", timeoutReason)
                    ]
                )
                try await performInitialFailoverIfNeeded(
                    shouldAllowFailover: shouldAllowFailover,
                    failure: timeoutFailure
                )
            }
        } catch let networkError as SwiftFulcrum.Client.Error.Network {
            await updateConnectionState(failureState)
            task.cancel(with: .goingAway, reason: "Network error during connect.".data(using: .utf8))
            try await performInitialFailoverIfNeeded(
                shouldAllowFailover: shouldAllowFailover,
                failure: SwiftFulcrum.Client.Error.transport(.network(networkError))
            )
        } catch {
            await updateConnectionState(failureState)
            task.cancel(with: .goingAway, reason: "Connect failed.".data(using: .utf8))
            try await performInitialFailoverIfNeeded(
                shouldAllowFailover: shouldAllowFailover,
                failure: error
            )
        }
    }
    
    private func performInitialFailoverIfNeeded(
        shouldAllowFailover: Bool,
        failure: Error
    ) async throws {
        guard shouldAllowFailover else { throw failure }
        
        recordWebSocketEvent(
            SwiftFulcrumDiagnostics.Event.webSocketConnectFailover,
            level: .error,
            fields: SwiftFulcrumDiagnostics.errorFields(failure)
        )
        
        do {
            await updateConnectionState(.reconnecting)
            try await reconnector.attemptReconnection(
                for: self,
                shouldCancelReceiver: true,
                isInitialConnection: true
            )
        } catch {
            recordWebSocketEvent(
                SwiftFulcrumDiagnostics.Event.webSocketConnectFailoverExhausted,
                level: .error,
                fields: SwiftFulcrumDiagnostics.errorFields(error)
            )
            
            throw error
        }
    }
    
    func reconnect(with url: URL? = nil) async throws {
        await disconnect(with: "WebSocketConnection.reconnect()")
        await updateConnectionState(.reconnecting)
        do {
            try await reconnector.attemptReconnection(for: self, with: url, shouldCancelReceiver: false)
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
        recordWebSocketEvent(
            SwiftFulcrumDiagnostics.Event.webSocketDisconnect,
            level: .info,
            fields: [
                SwiftFulcrumDiagnostics.publicField("close_code", finalInformation.code.rawValue),
                SwiftFulcrumDiagnostics.privateField("reason", finalInformation.reason ?? "")
            ]
        )
        emitLifecycle(.disconnected(code: finalInformation.code, reason: finalInformation.reason))
    }
}
